pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('DOCKER_HUB_CREDENTIAL')
        SONAR_TOKEN = 'squ_07f15378ce51de6663f3a5e78450455d8cd0beb1'
        SONAR_HOST_URL = 'http://13.39.234.170:9000'
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
                echo 'Building the application...'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                sh """
                    mvn clean org.jacoco:jacoco-maven-plugin:prepare-agent install sonar:sonar \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                """
            }
        }

        stage('Check Code Coverage') {
            steps {
                script {
                    echo 'Fetching code coverage from SonarQube...'
                    def response = sh(
                        script: """
                            curl -s -H 'Authorization: Bearer ${SONAR_TOKEN}' \
                            '${SONAR_HOST_URL}/api/measures/component?component=${COMPONENT_KEY}&metricKeys=coverage'
                        """,
                        returnStdout: true
                    ).trim()

                    try {
                        def coverage = sh(
                            script: "echo '${response}' | jq -r '.component.measures[0].value'",
                            returnStdout: true
                        ).trim().toDouble()

                        echo "Code Coverage: ${coverage}%"

                        if (coverage < COVERAGE_THRESHOLD) {
                            error "Code coverage is below the threshold of ${COVERAGE_THRESHOLD}%. Aborting pipeline."
                        }
                    } catch (Exception e) {
                        error "Failed to parse code coverage: ${e.message}. Response: ${response}"
                    }
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                echo 'Building and pushing Docker image...'
                script {
                    sh """
                        echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                        docker build -t ihomziak/restaurant-listing-ms:${VERSION} .
                        docker push ihomziak/restaurant-listing-ms:${VERSION}
                    """
                }
            }
        }

        stage('Cleanup Workspace') {
            steps {
                echo 'Cleaning up workspace...'
                deleteDir()
            }
        }

        stage('Update Image Tag in GitOps') {
            steps {
                echo 'Updating image tag in GitOps repository...'
                checkout scmGit(
                    branches: [[name: '*/master']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'git-ssh',
                        url: 'git@github.com:IvanHomziak/fd-deployment.git'
                    ]]
                )
                script {
                    sh """
                        sed -i "s|image:.*|image: ihomziak/restaurant-listing-ms:${VERSION}|" aws/restaurant-manifest.yml
                        git add .
                        git commit -m "Update image tag to ${VERSION}"
                    """
                    sshagent(['git-ssh']) {
                        sh 'git push origin master'
                    }
                }
            }
        }

    }

    post {
        always {
            echo 'Pipeline execution complete.'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
    }
}
