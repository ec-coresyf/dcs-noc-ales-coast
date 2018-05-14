// node('ci-community') {
//   stage 'Checkout'
//   checkout scm
//   stage 'Setup environment'
//   env.PATH = "${tool 'apache-maven-3.0.5'}/bin:${env.PATH}"
//   stage 'Package and Deploy'
//   sh 'mvn deploy'
// }


def artserver = Artifactory.server('repository.terradue.com')
def buildInfo = Artifactory.newBuildInfo()
buildInfo.env.capture = true

pipeline {
	options {
    // Kepp 5 builds history
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  agent { 
    node { 
      // community builder
      label 'ci-community-docker' 
    }
  }

  stages {
 
    stage('Package NOC_ALES_jason1_docker') {
      steps {
       
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -X -B deploy'
        }
      }
     }
    

  }
}
