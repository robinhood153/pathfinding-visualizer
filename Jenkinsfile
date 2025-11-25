pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    ci: jenkins
spec:
  containers:

    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command:
        - /busybox/cat
      tty: true
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: sonar-scanner
      image: sonarsource/sonar-scanner-cli:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: kubeconfig-secret
          mountPath: /kube
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: jnlp
      image: jenkins/inbound-agent:latest
      args: ["$(JENKINS_SECRET)", "$(JENKINS_NAME)"]
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

  volumes:
    - name: kaniko-secret
      secret:
        secretName: nexus-secret

    - name: kubeconfig-secret
      secret:
        secretName: kubeconfig-secret

    - name: workspace-volume
      emptyDir: {}
'''
        }
    }

    environment {
        REGISTRY = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"
        IMAGE_NAME = "my-repository/pathfinder"
        FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
        NAMESPACE = "2401019"
        SONAR_KEY = "2401019-pathfinding-visulaizer"
    }

    stages {

        stage('Build Image with Kaniko') {
            steps {
                container('kaniko') {
                    sh '''
                        echo ">>> Building & Pushing using Kaniko"
                        /kaniko/executor \
                          --context `pwd` \
                          --dockerfile `pwd`/Dockerfile \
                          --destination=${FULL_IMAGE}:v1 \
                          --skip-tls-verify
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withCredentials([string(credentialsId: '2401019-pathfinding-visulaizer', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            echo ">>> Running SonarQube Scan"
                            sonar-scanner \
                              -Dsonar.projectKey=${SONAR_KEY} \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://sonarqube.imcc.com \
                              -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        echo ">>> Applying Deployment"
                        kubectl apply -f pathfinder-deployment.yaml -n ${NAMESPACE}

                        echo ">>> Waiting for rollout"
                        kubectl rollout status deployment/pathfinder-deployment -n ${NAMESPACE}
                    '''
                }
            }
        }
    }
}
