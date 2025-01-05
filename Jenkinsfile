pipeline {
    agent any

    environment {
        SONAR_TOKEN = 'squ_07f15378ce51de6663f3a5e78450455d8cd0beb1' // Update with your actual token
        SONAR_URL = 'http://13.39.234.170:9000' // Update with your actual SonarQube URL
        COMPONENT_KEY = 'com.ihomziak:restaurant-listing-ms'
        COVERAGE_THRESHOLD = 50.0
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/IvanHomziak/fd-restaurant-listing-ms.git'
            }
        }

        stage('Build') {
            steps {
                script {
                    def mvnHome = tool name: 'Maven', type: 'maven'
                    withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
                        sh 'mvn clean package -DskipTests'
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    def mvnHome = tool name: 'Maven', type: 'maven'
                    withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
                        sh 'mvn test'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def mvnHome = tool name: 'Maven', type: 'maven'
                    withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
                        sh """
                        mvn clean org.jacoco:jacoco-maven-plugin:prepare-agent install sonar:sonar \
                            -Dsonar.host.url=${SONAR_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Check Code Coverage') {
            steps {
                script {
                    // Fetch coverage from SonarQube
                    def response = sh(
                        script: """
                        curl -H 'Authorization: Bearer ${SONAR_TOKEN}' \
                        '${SONAR_URL}/api/measures/component?component=${COMPONENT_KEY}&metricKeys=coverage'
                        """,
                        returnStdout: true
                    ).trim()

                    // Parse the JSON response
                    def parsedJson = readJSON text: response
                    def coverageValueStr = parsedJson.component.measures[0].value
                    def coverageValue = coverageValueStr.toDouble() // Explicitly parse as Double

                    echo "Code Coverage: ${coverageValue}%"

                    // Compare the coverage value with the threshold
                    if (coverageValue < COVERAGE_THRESHOLD) {
                        error "Code coverage is below the threshold of ${COVERAGE_THRESHOLD}%. Aborting the pipeline."
                    }
                }
            }
        }


        stage('Docker Build and Push') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    sh """
                    docker build -t your-docker-repo/restaurant-listing-ms:latest .
                    docker login -u your-docker-username -p your-docker-password
                    docker push your-docker-repo/restaurant-listing-ms:latest
                    """
                }
            }
        }

        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }
    }
}
