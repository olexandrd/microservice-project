argocd-apps:
  applications:
    example-app: 
      namespace: argocd
      project: default
      source:
        repoURL: https://github.com/olexandrd/microservice-project.git
        path: charts/django-app
        targetRevision: cd
        helm:
          valueFiles:
            - values.yaml
          values: |
            config:
              POSTGRES_HOST: "${rds_host}"
              POSTGRES_USER: "${rds_username}"
              POSTGRES_NAME: "${rds_db_name}"
              POSTGRES_PASSWORD: "${rds_password}"
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true

  repositories:
    example-app:
      url: https://github.com/olexandrd/microservice-project.git

  repoConfig:
    insecure: "true"
    enableLfs: "true"
