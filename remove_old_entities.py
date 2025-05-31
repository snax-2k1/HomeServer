import requests
from datetime import datetime, timedelta
import json

# Home Assistant API configuration
HOME_ASSISTANT_URL = "http://your-home-assistant-url:8123"
API_TOKEN = "your-long-lived-access-token"
HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json",
}

# Define the threshold for inactivity (90 days)
THRESHOLD_DATE = datetime.now() - timedelta(days=90)

# Function to fetch all entities
def fetch_entities():
    url = f"{HOME_ASSISTANT_URL}/api/states"
    response = requests.get(url, headers=HEADERS)
    response.raise_for_status()
    return response.json()

# Function to remove an entity
def remove_entity(entity_id):
    url = f"{HOME_ASSISTANT_URL}/api/states/{entity_id}"
    response = requests.delete(url, headers=HEADERS)
    if response.status_code == 200:
        print(f"Successfully removed entity: {entity_id}")
    else:
        print(f"Failed to remove entity: {entity_id}. Status code: {response.status_code}")

# Main script
def main():
    print("Fetching entities...")
    entities = fetch_entities()
    old_entities = []

    for entity in entities:
        last_updated = datetime.fromisoformat(entity["last_updated"][:-1])
        if last_updated < THRESHOLD_DATE:
            old_entities.append({
                "entity_id": entity["entity_id"],
                "last_updated": last_updated.isoformat(),
            })

    if not old_entities:
        print("No entities found that haven't been contacted in over 90 days.")
        return

    print("Entities that haven't been contacted in over 90 days:")
    print(json.dumps(old_entities, indent=4))

    user_input = input("Do you want to delete these entities? (yes/no): ").strip().lower()
    if user_input == "yes":
        for entity in old_entities:
            remove_entity(entity["entity_id"])
    else:
        print("No entities were deleted.")

if __name__ == "__main__":
    main()
