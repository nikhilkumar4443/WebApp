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
        stage('Install Dependencies') {
            steps {
               
                def USER_INPUT = input(
                    message: 'do you want to deloy QR code',
                    parameters: [
                            [$class: 'ChoiceParameterDefinition',
                             choices: ['no','yes'].join('\n'),
                             name: 'input',
                             description: 'Menu - select box option']
                    ])

            echo "The answer is: ${USER_INPUT}"

            if( "${USER_INPUT}" == "yes"){
                 sh """
                  echo "Performing the action"
                 """                
            } else {
                 sh """
                  echo "Skipping the action"
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
