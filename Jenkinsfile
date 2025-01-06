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
                        def jsonSlurper = new groovy.json.JsonSlurper()
                        def parsedResponse = jsonSlurper.parseText(response)

                        def coverage = parsedResponse?.component?.measures?.find { it.metric == 'coverage' }?.value?
                        if (coverage == null) {
                            error "Coverage value is missing in the SonarQube response. Response: ${response}"
                        }

                        echo "Code Coverage: ${coverage}%"

                        if (coverage < COVERAGE_THRESHOLD) {
                            error "Code coverage is below the threshold of ${COVERAGE_THRESHOLD}%. Aborting pipeline."
                        }
                    } catch (Exception e) {
                        error "Failed to parse or validate code coverage: ${e.message}. Response: ${response}"
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
                script {
                    retry(3) {
                        checkout scmGit(
                            branches: [[name: '*/main']],
                            extensions: [],
                            userRemoteConfigs: [[
                                credentialsId: 'git-ssh',
                                url: 'git@github.com:IvanHomziak/fd-deployment.git'
                            ]]
                        )
                    }
                    sh """
                        git checkout main || git checkout -b main
                        if [ ! -f aws/restaurant-manifest.yml ]; then
                            echo "Manifest file not found!"
                            exit 1
                        fi
                        git config user.name "IvanHomziak"
                        git config user.email "ivan.homziak@gmail.com"
                        sed -i "s|image:.*|image: ihomziak/restaurant-listing-ms:${VERSION}|" aws/restaurant-manifest.yml
                        git add .
                        git commit -m "Update image tag to ${VERSION}"
                    """
                    sshagent(['git-ssh']) {
                        sh """
                            for i in {1..3}; do
                                git push origin main && break || sleep 5
                            done
                        """
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