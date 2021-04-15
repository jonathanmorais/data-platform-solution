
PROJECT_PATH=$(shell pwd)
PROJECT_NAME="ml-platform"

lambda_zip_processor:
	cd lambda/client_transform
	zip -r -9 ../../client_processor.zip .

validate:
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform validate

plan:
	cd $(PROJECT_PATH)/infra/environments/prod && rm -rf .terraform
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform plan

apply:
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform apply --auto-approve

destroy:
	cd $(PROJECT_PATH)/infra/environments/prod && terraform init --backend-config="access_key=$(ACCESS_KEY)" --backend-config="secret_key=$(ACCESS_SECRET_KEY)"
	cd $(PROJECT_PATH)/infra/environments/prod && terraform destroy --auto-approve

jupyter-build:
	cd $(PROJECT_PATH)/docker/ && docker build -t $(PROJECT_NAME) .

jupyter-run:
	docker run --name $(PROJECT_NAME) --rm \
	-p 10000:8888 \
	--network=host \
	-e JUPYTER_ENABLE_LAB=yes \
	-e ACCESS_KEY=${ACCESS_KEY} \
	-e ACCESS_SECRET_KEY=${ACCESS_SECRET_KEY} \
	-v $$PWD/docker/workspace:/home/jovyan/work $(PROJECT_NAME)

jupyter-remove:
	docker rm -f $(PROJECT_NAME)
