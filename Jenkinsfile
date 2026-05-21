pipeline {
    agent any

    environment {

        GIT_REPO_URL       = "https://github.com/ArpitChouksey/PersonalProject.git"

        GIT_BRANCH         = "P4-S3-CloudFront-Serverless"

        AWS_REGION         = "ap-south-1"

        S3_BUCKET          = "arpit-static-site-demo-001"

        CLOUDFRONT_DIST_ID = "E2EFMVXJ2Q2AZZ"

        WEBSITE_DIR        = "PersonalProject/static_website"

        AWS_CREDS = credentials('aws-creds')
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                sh '''
                    echo "Cloning GitHub Repository"

                    rm -rf PersonalProject

                    git clone -b ${GIT_BRANCH} ${GIT_REPO_URL}

                    echo "Repository Cloned Successfully"

                    ls -la
                '''
            }
        }

        stage('Verify Repository Files') {
            steps {
                sh '''
                    echo "Current Workspace"
                    pwd

                    echo "Repository Files"
                    ls -la PersonalProject

                    echo "Website Files"
                    ls -la ${WEBSITE_DIR}
                '''
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                sh '''
                    echo "Configuring AWS Credentials"

                    aws configure set aws_access_key_id $AWS_CREDS_USR

                    aws configure set aws_secret_access_key $AWS_CREDS_PSW

                    aws configure set default.region ${AWS_REGION}
                '''
            }
        }

        stage('Validate AWS Access') {
            steps {
                sh '''
                    echo "Checking AWS CLI"
                    aws --version

                    echo "Checking S3 Access"
                    aws s3 ls
                '''
            }
        }

        stage('Upload Website To S3') {
            steps {
                sh '''
                    echo "Uploading Static Website To S3"

                    aws s3 sync ${WEBSITE_DIR} s3://${S3_BUCKET} --delete

                    echo "Website Uploaded Successfully"
                '''
            }
        }

        stage('Invalidate CloudFront Cache') {
            steps {
                sh '''
                    echo "Creating CloudFront Invalidation"

                    aws cloudfront create-invalidation \
                    --distribution-id ${CLOUDFRONT_DIST_ID} \
                    --paths "/*"

                    echo "CloudFront Cache Invalidated"
                '''
            }
        }

        stage('Deployment Verification') {
            steps {
                sh '''
                    echo "Verifying S3 Website"

                    aws s3 ls s3://${S3_BUCKET}

                    echo "Deployment Completed Successfully"
                '''
            }
        }
    }

    post {

        always {
            echo 'Pipeline Finished.'
        }

        success {
            echo 'Static Website Deployment Successful!'
        }

        failure {
            echo 'Pipeline Execution Failed!'
        }
    }
}
