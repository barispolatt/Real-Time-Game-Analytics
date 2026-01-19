import time
import json
import random
import requests
from faker import Faker

# Configurations
SERVER_IP = "YOUR_SERVER_IP" 
LOGSTASH_URL = f"http://{SERVER_IP}:5044"

fake = Faker()

# random game options
EVENT_TYPES = ["login", "match_start", "kill", "death", "purchase", "match_end"]
WEAPONS = ["AK-47", "M4A1", "AWP", "Desert Eagle", "Knife"]
ITEMS = ["Health Potion", "Armor", "Grenade", "Smoke"]
MAPS = ["Dust2", "Mirage", "Inferno", "Nuke"]

def generate_event():
    """Creates random game event"""
    event_type = random.choice(EVENT_TYPES)
    
    data = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()),
        "user_id": random.randint(1000, 9999),
        "username": fake.user_name(),
        "ip": fake.ipv4(), # GeoIP icin rastgele IP
        "event": event_type,
        "map": random.choice(MAPS),
        "latency_ms": random.randint(20, 150)
    }

    # add detail based on event type
    if event_type == "kill":
        data["weapon"] = random.choice(WEAPONS)
        data["victim"] = fake.user_name()
    elif event_type == "purchase":
        data["item"] = random.choice(ITEMS)
        data["cost"] = random.randint(100, 3000)

    return data

def send_data():
    """creates data in infinite loop"""
    print(f"Traffic starting -> {LOGSTASH_URL}")
    print("Stop with CTRL+C")
    
    while True:
        try:
            event = generate_event()
            # HTTP POST request to LogStash in json format
            response = requests.post(LOGSTASH_URL, json=event, timeout=2)
            
            if response.status_code == 200:
                print(f"Send: [{event['event']}] - {event['username']} ({event['ip']})")
            else:
                print(f"Error Code: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print("Connection Error! The server may not be ready yet or the IP address is incorrect.")
        except Exception as e:
            print(f"Unexpected error: {e}")

        time.sleep(random.uniform(0.5, 2.0))

if __name__ == "__main__":
    if SERVER_IP == "YOUR_SERVER_IP":
        print("Error: Update the SERVER_IP variable inside the script!")
    else:
        send_data()