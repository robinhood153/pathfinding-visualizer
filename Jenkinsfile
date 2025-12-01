pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:

  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ["cat"]
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    securityContext:
      runAsUser: 0
    env:
    - name: KUBECONFIG
      value: /kube/config
    volumeMounts:
    - name: kubeconfig-secret
      mountPath: /kube/config
      subPath: kubeconfig

  - name: dind
    image: docker:dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    args:
    - "--storage-driver=overlay2"
    volumeMounts:
    - name: docker-config
      mountPath: /etc/docker/daemon.json
      subPath: daemon.json
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: jnlp
    image: jenkins/inbound-agent:3309.v27b_9314fd1a_4-1
    env:
    - name: JENKINS_AGENT_WORKDIR
      value: "/home/jenkins/agent"
    volumeMounts:
    - mountPath: "/home/jenkins/agent"
      name: workspace-volume

  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: docker-config
    configMap:
      name: docker-daemon-config
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
'''
        }
    }

    environment {
        REGISTRY    = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"
        IMAGE_REPO  = "my-repository/pathfinder"
        FULL_IMAGE  = "${REGISTRY}/${IMAGE_REPO}"
        NAMESPACE   = "2401019"
        SONAR_KEY   = "2401019-pathfinding-visulaizer"
    }

    stages {

        stage('CHECK') {
            steps {
                echo "DEBUG >>> UPDATED FRIEND-STYLE PIPELINE IS ACTIVE"
            }
        }

        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        echo "Waiting for Docker daemon..."
                        sleep 15
                        docker build -t pathfinder:latest .
                    '''
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                container('sonar-scanner') {
                    withCredentials([string(credentialsId: '2401019-pathfinding-visulaizer', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=2401019-pathfinding-visulaizer \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000 \
                              -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Login to Nexus Registry') {
            steps {
                container('dind') {
                    sh '''
                        docker --version
                        sleep 10
                        docker login ${REGISTRY} -u admin -p Changeme@2025
                    '''
                }
            }
        }

        stage('Tag + Push Image') {
            steps {
                container('dind') {
                    sh '''
                        docker tag pathfinder:latest ${FULL_IMAGE}:latest
                        docker push ${FULL_IMAGE}:latest
                    '''
                }
            }
        }


        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    dir('k8s-deployment') {
                        sh '''
                            echo "Applying Deployment..."
                            kubectl apply -f pathfinder-deployment.yaml -n ${NAMESPACE}

                            echo "Pods:"
                            kubectl get pods -n ${NAMESPACE}
                        '''
                    }
                }
            }
        }

        stage('DEBUG POD STATUS') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "=== POD LIST ==="
                        kubectl get pods -n ${NAMESPACE}

                        POD=$(kubectl get pods -n ${NAMESPACE} -o jsonpath="{.items[0].metadata.name}")

                        echo "=== DESCRIBE POD ==="
                        kubectl describe pod $POD -n ${NAMESPACE}
                    '''
                }
            }
        }
    }
}
