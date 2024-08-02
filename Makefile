common_params = --no-confirm-changeset --no-fail-on-empty-changeset --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
run_env = ParameterKey=RunEnvironment,ParameterValue
prod_aws_account = 298118738376
dev_aws_account = 427040638965
src_directory_root = src/
integration_test_directory_root = tests/live_integration/

check_account_prod:
	@aws_account_id=$$(aws sts get-caller-identity --query Account --output text); \
	if [ "$$aws_account_id" != "$(prod_aws_account)" ]; then \
		echo "Error: running in incorrect account $$aws_account_id, expected account ID $(prod_aws_account)"; \
		exit 1; \
	fi
check_account_dev:
	@aws_account_id=$$(aws sts get-caller-identity --query Account --output text); \
	if [ "$$aws_account_id" != "$(dev_aws_account)" ]; then \
		echo "Error: running in incorrect account $$aws_account_id, expected account ID $(dev_aws_account)"; \
		exit 1; \
	fi

build:
	sam build --template-file cloudformation/main.yml

local:
	sam local start-api --env-vars local.env.json --warm-containers EAGER

deploy_prod: check_account_prod build 
	aws sts get-caller-identity --query Account --output text
	sam deploy $(common_params) --parameter-overrides $(run_env)=prod

deploy_dev: check_account_dev build
	sam deploy $(common_params) --parameter-overrides $(run_env)=dev

install_test_deps:
	pip install -r $(integration_test_directory_root)/requirements.txt
	pip install -r $(src_directory_root)/requirements-testing.txt

test_live_integration: install_test_deps
	pytest -rP $(integration_test_directory_root)

test_unit: install_test_deps
	pytest -rP $(src_directory_root)
