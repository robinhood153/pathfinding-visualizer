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
    - name: dind
      image: docker:dind
      securityContext:
        privileged: true
      args: ["--storage-driver=overlay2"]
      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""
      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker

    - name: sonar-scanner
      image: sonarsource/sonar-scanner-cli:latest
      command: [ "cat" ]
      tty: true

    - name: kubectl
      image: bitnami/kubectl:latest
      command: [ "cat" ]
      tty: true
      volumeMounts:
        - name: kubeconfig-secret
          mountPath: /kube
  volumes:
    - name: docker-graph-storage
      emptyDir: {}
    - name: kubeconfig-secret
      secret:
        secretName: kubeconfig-secret
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

        stage('Docker Build') {
            steps {
                container('dind') {
                    sh '''
                        echo ">>> Building Docker Image"
                        docker build -t ${FULL_IMAGE}:latest .
                        docker images
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

        stage('Push to Nexus') {
            steps {
                container('dind') {
                    sh '''
                        echo ">>> Logging into Nexus"
                        docker login ${REGISTRY} -u admin -p Changeme@2025

                        echo ">>> Tagging image"
                        docker tag ${FULL_IMAGE}:latest ${FULL_IMAGE}:v1

                        echo ">>> Pushing image"
                        docker push ${FULL_IMAGE}:v1
                    '''
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
