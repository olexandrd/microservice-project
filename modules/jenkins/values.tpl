controller:
  admin:
    username: admin
    password: admin123

  serviceType: LoadBalancer
  servicePort: 80
  service:
    port: 80
    targetPort: 8080

  resources:
    limits:
      cpu: "500m"
      memory: "1Gi"
    requests:
      cpu: "250m"
      memory: "512Mi"

  persistentVolume:
    enabled: true
    storageClass: "ebs-sc"
    size: 8Gi

  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - credentials-binding:latest
    - github:latest
    - docker-plugin:latest
    - docker-workflow:latest
    - job-dsl:latest

  serviceAccount:
     name: jenkins-sa
     create: false
  JCasC:
    
    configScripts:
      credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - usernamePassword:
                      scope: GLOBAL
                      id: github-token
                      username: ${github_username}
                      password: ${github_token}
                      description: GitHub PAT
      seed-job: |
        jobs:
          - script: >
              job('seed-job') {
                description('Job to generate pipeline for Django project')
                scm {
                  git {
                    remote {
                      url("${github_repo_url}")
                      credentials('github-token')
                    }
                    branches("*/${github_branch}")
                  }
                }
                steps {
                  dsl {
                    text('''
                      pipelineJob("django-docker") {
                        definition {
                          cpsScm {
                            scriptPath('django/Jenkinsfile')
                            scm {
                              git {
                                remote {
                                  url("${github_repo_url}")
                                  credentials("github-token")
                                }
                                branches("*/${github_branch}")
                              }
                            }
                          }
                        }
                      }
                    ''')
                  }
                }
              }
      script-approval: |
        unclassified:
          scriptApproval:
            approvedSignatures:
              - "new javaposse.jobdsl.dsl.DslScriptLoader java.lang.String java.lang.ClassLoader"
              - "method org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition create org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition"