script {
            // Define Variable
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
