#!/usr/bin/groovy

static def getUser(String branchName) {
    if (branchName == "prod") {
        return "dh-jenkins-aws-prd"
    } else if (branchName == "master") {
        return "dh-jenkins-aws-dev"
    } else if (branchName == "stg") {
        return "dh-jenkins-aws-stg"
    } else if (branchName == "prf") {
        return "dh-jenkins-aws-prf"
    } else if (branchName == "qas") {
        return "dh-jenkins-aws-qas"
    }
}

static def getStage(String branchName) {
    if (branchName == "prod") {
        return "prd"
    } else if (branchName == "stg") {
        return "stg"
    } else if (branchName == "prf") {
        return "prf"
    } else if (branchName == "qas") {
        return "qas"
    }
    return "dev"
}


pipeline{
    agent {
        node('maven01')
    }

    options{
        timestamps()
    }

    environment {
        DEFAULT_REGION = 'us-west-2'
        IMAGE = UUID.randomUUID().toString()
        CONTAINER = UUID.randomUUID().toString()
        DEP_USER = getUser("${env.BRANCH_NAME}")
        DEP_STAGE = getStage("${env.BRANCH_NAME}")
    }

    stages{
        stage('Code Checkout'){
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                input ("APPROVE")
                sh """
                    docker build -t ${IMAGE} . 
                    docker run -t -d --name ${CONTAINER} ${IMAGE}:latest
                """
            }
        }
        stage('Lint') {
            steps {
                sh """
                    docker exec -i ${CONTAINER} make install
                    docker exec -i ${CONTAINER} make lint
                """
            }
        }
        stage('Run SonarQube') {
            steps{
                withCredentials([string(credentialsId: 'sonar-dh-login', variable: 'SONAR_AUTH_TOKEN')]) {
                        script{
                            withFolderProperties{
                                script{
                                    def sonarOptions = "-Dsonar.host.url=${env.SONAR_HOST_URL} -Dsonar.login=${env.SONAR_AUTH_TOKEN} -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} -Dsonar.projectVersion='1.0'"
                                    echo "Sonar host URL: ${env.SONAR_HOST_URL}"
                                    echo "Running SonarQube Static Analysis for v${env.BRANCH_NAME}"
                                    sh "mvn -e -B install sonar:sonar ${sonarOptions}"
                                    echo "SonarQube Static Analysis was SUCCESSFUL for v${env.BRANCH_NAME}"
                                }
                            }

                        }
                }
            }
        }

        stage('Serverless Package') {
            when {
                anyOf {
                    branch 'master'; branch 'prod'; branch 'stg'; branch 'prf'; branch 'qas'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',credentialsId: "${DEP_USER}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) { 
                    sh """
                        docker exec -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -i ${CONTAINER} make -e STAGE=${DEP_STAGE} package
                    """
                }
            }
        }

        stage('Deploy'){
            when {
                anyOf {
                    branch 'master'; branch 'prod'; branch 'stg'; branch 'prf'; branch 'qas'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',credentialsId: "${DEP_USER}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {                     
                    sh """
                        docker exec -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -i ${CONTAINER} make -e STAGE=${DEP_STAGE} deploy
                        docker exec -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -i ${CONTAINER} make -e STAGE=${DEP_STAGE} up
                    """              
                } 
            }
        }

        stage('create transition table'){
            when {
                allOf {
                    expression{"${env.BRANCH_NAME}" == 'master' || "${env.BRANCH_NAME}" == 'stg' || "${env.BRANCH_NAME}" == 'prod' || "${env.BRANCH_NAME}" == 'prf' || "${env.BRANCH_NAME}" == 'prf'}
                    changeset "_version.py"
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',credentialsId: "${DEP_USER}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {                     
                    sh """
                        docker exec -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -i ${CONTAINER} make -e STAGE=${DEP_STAGE} transition
                    """            
                } 
            }
        }
    }
    post {
        success {
            script {
                echo "SUCCESS"
            }
        }
        always {
            sh """
                docker stop ${CONTAINER}
                docker rm ${CONTAINER}
                docker rmi ${IMAGE}:latest
            """
            cleanWs()
        }
    }
}
