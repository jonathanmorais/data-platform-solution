
PROJECT_PATH=$(shell pwd)

plan:
	cd $(PROJECT_PATH)/infra/environments/prod && rm -rf .terraform
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform plan

apply:
	cd $(PROJECT_PATH)/infra/environments/prod && terraform apply --auto-approve

destroy:
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform destroy --auto-approve	
