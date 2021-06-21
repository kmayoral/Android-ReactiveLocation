#!groovy
import groovy.transform.Field

@Field apkStashName
def gitRef
def scmVars

@Field tools

@Library('Utils@master')
import co.bird.Utils
@Field utils = new Utils()

@Field buildType

timestamps {
  node('android-agent') {
    try {
      stage('Checkout') {
        scmVars = checkout scm
        sh '''
          cleanWs()
          git config --global user.email "devops+jenkins@bird.co" && git config --global user.name "Jenkins"
        '''
        tools = load "jenkins/tools.groovy"
        buildType = tools.BuildType.DIFF

        apkStashName = "${scmVars.GIT_BRANCH}-${env.BUILD_NUMBER}"
        gitRef = scmVars.GIT_BRANCH
      }
      stage('Build') {
        docker.withRegistry('https://168995956934.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:ecs-credentials') {
          docker.build('local/android').inside('-v /root/.gradle:/root/.gradle -v /root/.android:/root/.android') {
            sh "./gradlew clean android-reactive-location:build"
          }
        }
      }
      if (scmVars.GIT_BRANCH == "master") {
        stage('Publish') {
          def secrets = [
            [$class: 'VaultSecret', path: "secret/services/jenkins/artifactory", secretValues: [
              [$class: 'VaultSecretValue', envVar: 'ARTIFACTORY_USER', vaultKey: 'USER'],
              [$class: 'VaultSecretValue', envVar: 'ARTIFACTORY_API_KEY', vaultKey: 'API_KEY'],
            ]]
          ]
          wrap([$class: 'VaultBuildWrapper', vaultSecrets: secrets]) {
            sh "./gradlew android-reactive-location:publish -PreleaseVersionExt='${versionExt}'"
          }
          withCredentials([string(credentialsId: 'jenkins-github-api-secret', variable: 'TOKEN')]) {
            sh """
              curl -H "Authorization: token $TOKEN" \
                --request PATCH \
                --data '{"name":"android-reactive-location", "description": "Latest '\$(cat gradle.properties | grep majorMinor= | tr -d 'majorMinor=').${versionExt}'", "homepage": "https://jenkins.svc.bird.co/job/github/job/android-reactive-location/job/master/${env.BUILD_NUMBER}/"}' \
                https://api.github.com/repos/birdrides/android-reactive-location
            """
          }
        }
      }
    } catch (e) {
      currentBuild.result = 'FAILURE'
      throw e
    } finally {
      if (currentBuild.result == null) {
        currentBuild.result = 'SUCCESS'
      }
    }
  }
} //end timestamps
