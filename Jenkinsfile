pipeline {
    agent any

  
  stage('Build') {
    echo "building"
  }
  stage('Deploy to testing') {
    echo "deployed"
  }
  stage('QA Team certification') {
    input "Deploy to prod?"
  }
  stage('Deploy to prod') {
    echo "deployed"
  }

}
