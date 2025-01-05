pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('DOCKER_HUB_CREDENTIAL')
        SONAR_TOKEN = 'squ_07f15378ce51de6663f3a5e78450455d8cd0beb1'
        SONAR_URL = 'http://13.39.234.170:9000'
        COMPONENT_KEY = 'com.ihomziak:restaurant-listing-ms'
        COVERAGE_THRESHOLD = 50.0
        VERSION = "${env.BUILD_ID}"
    }

    tools {
        maven "Maven"
    }

    stages {
        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh """
                mvn clean org.jacoco:jacoco-maven-plugin:prepare-agent install sonar:sonar \
                -Dsonar.host.url=${SONAR_URL} \
                -Dsonar.login=${SONAR_TOKEN}
                """
            }
        }

        stage('Check Code Coverage') {
            steps {
                script {
                    def response = sh(
                        script: "curl -H 'Authorization: Bearer ${SONAR_TOKEN}' '${SONAR_URL}/api/measures/component?component=${COMPONENT_KEY}&metricKeys=coverage'",
                        returnStdout: true
                    ).trim()

                    // Parse the JSON response and extract coverage
                    def coverageJson = readJSON(text: response)
                    def coverageValue = coverageJson.component.measures[0].value.toDouble()

                    echo "Code Coverage: ${coverageValue}%"

                    if (coverageValue < COVERAGE_THRESHOLD) {
                        error "Code coverage is below the threshold of ${COVERAGE_THRESHOLD}%. Aborting the pipeline."
                    }
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker build -t ihomziak/restaurant-listing-ms:${VERSION} ."
                sh "docker push ihomziak/restaurant-listing-ms:${VERSION}"
            }
        }

        stage('Cleanup Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Update Image Tag in GitOps') {
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'git-ssh', url: 'git@github.com:IvanHomziak/fd-deployment.git']])
                script {
                    sh """
                    sed -i "s/image:.*/image: ihomziak\\/restaurant-listing-ms:${VERSION}/" aws/restaurant-manifest.yml
                    git add aws/restaurant-manifest.yml
                    git commit -m 'Update image tag'
                    """
                    sshagent(['git-ssh']) {
                        sh 'git push'
                    }
                }
            }
        }
    }
}
