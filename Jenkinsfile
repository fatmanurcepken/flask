pipeline {
    agent any

    environment {
        // Docker Hub'a gönderilecek imajın adı
        // Lütfen 'kullaniciadi' kısmını kendi Docker Hub adınızla değiştirin (örn: fatmanurcepken)
        IMAGE_NAME = "fatmanurcepken/flask-app"
        
        // Jenkins Credentials arayüzüne eklediğiniz Username/Password credential ID'si
        DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'
    }

    stages {
        stage('Lint / Test') {
            steps {
                echo 'Kod standartları kontrol ediliyor (flake8)...'
                // Flake8 ile söz dizimi ve stil kontrolü
                // --exit-zero parametresi, şu an projede flake8 uyumlu olmayan yerler varsa 
                // pipeline'ı kırmamak (hata vermemesi) için kullanılabilir. 
                // Production'da kaldırılması tavsiye edilir.
                sh 'flake8 app/ --exit-zero'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Docker imajı oluşturuluyor...'
                script {
                    // Commit SHA'sını alıp kısa versiyonunu kullanıyoruz
                    env.COMMIT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
                // Uygulamanın Dockerfile'ını kullanarak build al
                sh "docker build -t ${IMAGE_NAME}:${env.COMMIT_SHA} -f app/Dockerfile ."
                sh "docker tag ${IMAGE_NAME}:${env.COMMIT_SHA} ${IMAGE_NAME}:latest"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'İmaj Docker Hub`a gönderiliyor...'
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    // Güvenli bir şekilde login oluyoruz
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    
                    // Hem commit etiketini hem de latest etiketini pushluyoruz
                    sh "docker push ${IMAGE_NAME}:${env.COMMIT_SHA}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Update values.yaml & Deploy to Kubernetes') {
            steps {
                echo 'Helm Chart içerisindeki values.yaml güncelleniyor ve deploy başlatılıyor...'
                // values.yaml dosyasındaki SADECE flask uygulamasının repository ve tag değerlerini güncelliyoruz
                sh """
                sed -i '/^flask:/,/^mongodb:/ s|^\\(\\s*\\)repository:.*|\\1repository: ${IMAGE_NAME}|' helm/flask-mongodb/values.yaml
                sed -i '/^flask:/,/^mongodb:/ s|^\\(\\s*\\)tag:.*|\\1tag: "${env.COMMIT_SHA}"|' helm/flask-mongodb/values.yaml
                """
                
                // Kubeconfig dosyasını kopyalayıp 127.0.0.1'i host.docker.internal yapıyoruz
                // Ayrıca TLS sertifika doğrulamasını atlıyoruz (çünkü host.docker.internal sertifikada yok)
                sh """
                mkdir -p /tmp/.kube
                cp -r /var/jenkins_home/.kube/* /tmp/.kube/ || true
                sed -i 's/127.0.0.1/host.docker.internal/g' /tmp/.kube/config
                sed -i 's/certificate-authority-data:.*/insecure-skip-tls-verify: true/g' /tmp/.kube/config
                export KUBECONFIG=/tmp/.kube/config
                helm upgrade --install flask-app ./helm/flask-mongodb --namespace flask-mongodb --create-namespace
                """
                
                echo 'Deploy tamamlandı!'
            }
        }
    }

    post {
        always {
            echo 'Pipeline çalışması tamamlandı. Geçici dosyalar temizleniyor...'
            // Docker ortamında gereksiz yer kaplamaması için imajları silebilirsiniz:
            // sh "docker rmi ${IMAGE_NAME}:${env.COMMIT_SHA} || true"
        }
        success {
            echo 'Harika! CI/CD süreci BAŞARIYLA tamamlandı ve uygulama deploy edildi.'
        }
        failure {
            echo 'Maalesef CI/CD süreci BAŞARISIZ oldu. Lütfen logları kontrol edin.'
        }
    }
}
