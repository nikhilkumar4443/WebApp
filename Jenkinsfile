pipeline{
    agent any

    options{
        timestamps()
    }

    stages{
        stage('Code Checkout'){
            steps {
                cleanWs()
                checkout scm
            }
        }
    stage('Wait for user to input text?') {
        steps {
            script {
                def userInput = input(id: 'userInput', message: 'Merge to?',
                parameters: [[$class: 'ChoiceParameterDefinition', defaultValue: 'strDef', 
                    description:'describing choices', name:'nameChoice', choices: "QA\nUAT\nProduction\nDevelop\nMaster"]
                ])

                println(userInput); //Use this value to branch to different logic if needed
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

