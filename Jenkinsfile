pipeline {
  agent {
    docker {
      image 'ivotron/dummybench'
    }
    
  }
  stages {
    stage('foo') {
      steps {
        sh 'echo bar'
      }
    }
  }
}