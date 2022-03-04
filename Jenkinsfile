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
            // Define Variable
             def USER_INPUT = input(
                    message: 'User input required - Some Yes or No question?',
                    parameters: [
                            [$class: 'ChoiceParameterDefinition',
                             choices: ['no','yes'].join('\n'),
                             name: 'input',
                             description: 'Menu - select box option']
                    ])

            echo "The answer is: ${USER_INPUT}"

            if( "${USER_INPUT}" == "yes"){
                """
                echo  "hello"
                """
                
            } else {
                println("Skkiping")
            }
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
