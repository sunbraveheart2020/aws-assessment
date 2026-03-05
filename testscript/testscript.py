import boto3
import json
import time
import requests
from concurrent.futures import ThreadPoolExecutor

# CONFIGURATION
COGNITO_REGION = "us-east-1"
USER_POOL_ID = "us-east-1_9m8h7ih79"
CLIENT_ID = "1ndk96bh6jhls3lbe8v4kfnggp"

USERNAME = "sunfangyong2018@gmail.com"
PASSWORD = "TempPass456!"

API_GW = {
    "us-east-1": "https://ixksyvg08i.execute-api.us-east-1.amazonaws.com",
    "eu-west-1": "https://o17c2unnob.execute-api.eu-west-1.amazonaws.com"
}

# STEP 1 — Authenticate with Cognito to get JWT
def get_jwt():
    client = boto3.client("cognito-idp", region_name=COGNITO_REGION)

    resp = client.initiate_auth(
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={
            "USERNAME": USERNAME,
            "PASSWORD": PASSWORD
        },
        ClientId=CLIENT_ID
    )

    return resp["AuthenticationResult"]["IdToken"]


# Helper: Call an endpoint and measure latency
def call_api(region, endpoint, jwt):
    url = f"{API_GW[region]}/{endpoint}"
    headers = {"Authorization": jwt}

    start = time.time()
    resp = requests.get(url, headers=headers)
    latency = (time.time() - start) * 1000  # ms

    try:
        payload = resp.json()
    except:
        payload = {"error": resp.text}

    return {
        "region": region,
        "endpoint": endpoint,
        "status": resp.status_code,
        "latency_ms": latency,
        "payload": payload
    }


# STEP 2 — Call /greet concurrently in both regions
# STEP 3 — Call /dispatch concurrently in both regions
def run_concurrent_tests(jwt):
    endpoints = ["greet", "dispatch"]
    regions = ["us-east-1", "eu-west-1"]

    tasks = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        for ep in endpoints:
            for reg in regions:
                tasks.append(executor.submit(call_api, reg, ep, jwt))

    return [t.result() for t in tasks]


# STEP 4 — Print results + assert region correctness
def print_results(results):
    print("\n================ TEST RESULTS ================\n")

    for r in results:
        expected = r["region"]
        actual = r["payload"].get("region", "UNKNOWN")

        ok = (expected == actual)

        print(f"[{r['endpoint'].upper()}] {expected}")
        print(f"  Status:   {r['status']}")
        print(f"  Latency:  {r['latency_ms']:.2f} ms")
        print(f"  Region OK: {ok}")
        print(f"  Payload:  {json.dumps(r['payload'])}")
        print("")

# MAIN
if __name__ == "__main__":
    print("Authenticating with Cognito...")
    jwt = get_jwt()
    print("JWT acquired.\n")

    print("Running concurrent tests...")
    results = run_concurrent_tests(jwt)

    print_results(results)
