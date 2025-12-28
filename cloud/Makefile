# Makefile for Hondani Shell project - Server Side


.PHONY: cloud-server test-cloud cloud-client


cloud-server:
	python3 cloud_server.py

cloud-client:
	python3 cloud_test_client.py


# Tests
test-cloud:
	PYTHONWARNINGS="ignore::DeprecationWarning:.*site-packages.*" pytest

test-client:
	pytest test_cloud_test_client.py

