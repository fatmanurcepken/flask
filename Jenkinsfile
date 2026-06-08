pipeline {
    agent any

    environment {
        IMAGE_NAME = "fatmanurcepken/flask-app"
        DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'
    }

    stages {
        stage('Lint / Test') {
            steps {
                echo 'Kod standartları kontrol ediliyor (flake8)...'
                sh 'flake8 app/ --exit-zero'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Docker imajı oluşturuluyor...'
                script {
                    env.COMMIT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
                sh "docker build -t ${IMAGE_NAME}:${env.COMMIT_SHA} -f app/Dockerfile ."
                sh "docker tag ${IMAGE_NAME}:${env.COMMIT_SHA} ${IMAGE_NAME}:latest"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'İmaj Docker Hub`a gönderiliyor...'
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${env.COMMIT_SHA}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Update values.yaml & Deploy to Kubernetes') {
            steps {
                echo 'Helm Chart güncelleniyor ve deploy başlatılıyor...'
                sh """
                sed -i '/^flask:/,/^mongodb:/ s|^\\(\\s*\\)repository:.*|\\1repository: ${IMAGE_NAME}|' helm/flask-mongodb/values.yaml
                sed -i '/^flask:/,/^mongodb:/ s|^\\(\\s*\\)tag:.*|\\1tag: \"${env.COMMIT_SHA}\"|' helm/flask-mongodb/values.yaml
                """

                sh """
                mkdir -p /tmp/.kube
                cp -r /var/jenkins_home/.kube/* /tmp/.kube/ || true
                sed -i 's|server:.*|server: https://minikube:8443|g' /tmp/.kube/config
                sed -i 's/certificate-authority-data:.*/insecure-skip-tls-verify: true/g' /tmp/.kube/config
                sed -i 's/certificate-authority:.*/insecure-skip-tls-verify: true/g' /tmp/.kube/config
                export KUBECONFIG=/tmp/.kube/config
                helm upgrade --install flask-app ./helm/flask-mongodb --namespace flask-mongodb --create-namespace
                """

                echo 'Deploy tamamlandı!'
            }
        }
    }

    post {
        always {
            echo 'Pipeline tamamlandı.'
        }
        success {
            echo 'CI/CD süreci başarıyla tamamlandı ve uygulama deploy edildi.'
        }
        failure {
            echo 'CI/CD süreci başarısız oldu. Lütfen logları kontrol edin.'
        }
    }
}
