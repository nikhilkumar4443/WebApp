pipeline {
    agent any

    stages {
        stage('Code Checkout'){
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('Hello') {
             when {
                allOf {
                    changeset "scripts/**"
                }
            }
            steps {
                echo 'Hello World'
            }
        }
    }
}
