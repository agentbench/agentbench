#!/usr/bin/env bash
set -euo pipefail
WS="$1"

cat > "$WS/inventory.py" << 'PYEOF'
# Inventory management module - needs refactoring
import json
import os
from datetime import datetime

items = {}
transaction_log = []

def add_item(name, quantity, price):
    if name in items:
        items[name]['quantity'] = items[name]['quantity'] + quantity
        items[name]['price'] = price
        items[name]['updated'] = datetime.now().isoformat()
    else:
        items[name] = {'quantity': quantity, 'price': price, 'created': datetime.now().isoformat(), 'updated': datetime.now().isoformat()}
    transaction_log.append({'action': 'add', 'item': name, 'quantity': quantity, 'price': price, 'timestamp': datetime.now().isoformat()})
    return items[name]

def remove_item(name, quantity):
    if name not in items:
        raise ValueError(f"Item '{name}' not found")
    if items[name]['quantity'] < quantity:
        raise ValueError(f"Not enough stock for '{name}': have {items[name]['quantity']}, need {quantity}")
    items[name]['quantity'] = items[name]['quantity'] - quantity
    items[name]['updated'] = datetime.now().isoformat()
    transaction_log.append({'action': 'remove', 'item': name, 'quantity': quantity, 'timestamp': datetime.now().isoformat()})
    if items[name]['quantity'] == 0:
        del items[name]
    return True

def get_item(name):
    if name in items:
        return items[name].copy()
    return None

def get_all_items():
    result = {}
    for name in items:
        result[name] = items[name].copy()
    return result

def get_total_value():
    total = 0
    for name in items:
        total = total + items[name]['quantity'] * items[name]['price']
    return total

def search_items(query):
    results = {}
    for name in items:
        if query.lower() in name.lower():
            results[name] = items[name].copy()
    return results

def get_low_stock(threshold=5):
    result = {}
    for name in items:
        if items[name]['quantity'] <= threshold:
            result[name] = items[name].copy()
    return result

def apply_discount(name, percent):
    if name not in items:
        raise ValueError(f"Item '{name}' not found")
    if percent < 0 or percent > 100:
        raise ValueError("Discount must be between 0 and 100")
    old_price = items[name]['price']
    items[name]['price'] = items[name]['price'] * (1 - percent / 100)
    items[name]['updated'] = datetime.now().isoformat()
    transaction_log.append({'action': 'discount', 'item': name, 'old_price': old_price, 'new_price': items[name]['price'], 'percent': percent, 'timestamp': datetime.now().isoformat()})
    return items[name]['price']

def bulk_add(item_list):
    added = []
    for item in item_list:
        name = item['name']
        quantity = item['quantity']
        price = item['price']
        add_item(name, quantity, price)
        added.append(name)
    return added

def export_to_json(filepath):
    data = {'items': get_all_items(), 'exported_at': datetime.now().isoformat(), 'total_value': get_total_value()}
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)
    return filepath

def import_from_json(filepath):
    with open(filepath, 'r') as f:
        data = json.load(f)
    for name, info in data['items'].items():
        items[name] = info
    return len(data['items'])

def get_transaction_log():
    return transaction_log.copy()

def clear_transaction_log():
    transaction_log.clear()

def reset():
    items.clear()
    transaction_log.clear()
PYEOF

cat > "$WS/test_inventory.py" << 'PYEOF'
"""Tests for inventory module - DO NOT MODIFY."""
import pytest
import os
import json
from inventory import (add_item, remove_item, get_item, get_all_items,
                       get_total_value, search_items, get_low_stock,
                       apply_discount, bulk_add, export_to_json,
                       import_from_json, reset)

@pytest.fixture(autouse=True)
def clean_state():
    reset()
    yield
    reset()

def test_add_new_item():
    result = add_item("Widget", 10, 5.99)
    assert result['quantity'] == 10
    assert result['price'] == 5.99

def test_add_existing_item():
    add_item("Widget", 10, 5.99)
    result = add_item("Widget", 5, 6.99)
    assert result['quantity'] == 15
    assert result['price'] == 6.99

def test_remove_item():
    add_item("Widget", 10, 5.99)
    assert remove_item("Widget", 3) == True
    item = get_item("Widget")
    assert item['quantity'] == 7

def test_remove_item_not_found():
    with pytest.raises(ValueError, match="not found"):
        remove_item("Nonexistent", 1)

def test_remove_insufficient_stock():
    add_item("Widget", 5, 5.99)
    with pytest.raises(ValueError, match="Not enough stock"):
        remove_item("Widget", 10)

def test_remove_all_stock():
    add_item("Widget", 5, 5.99)
    remove_item("Widget", 5)
    assert get_item("Widget") is None

def test_get_total_value():
    add_item("Widget", 10, 5.00)
    add_item("Gadget", 5, 10.00)
    assert get_total_value() == 100.00

def test_search_items():
    add_item("Blue Widget", 10, 5.99)
    add_item("Red Widget", 5, 7.99)
    add_item("Gadget", 3, 12.99)
    results = search_items("widget")
    assert len(results) == 2
    assert "Gadget" not in results

def test_get_low_stock():
    add_item("Widget", 3, 5.99)
    add_item("Gadget", 10, 12.99)
    low = get_low_stock(5)
    assert "Widget" in low
    assert "Gadget" not in low

def test_apply_discount():
    add_item("Widget", 10, 100.00)
    new_price = apply_discount("Widget", 25)
    assert new_price == 75.00

def test_bulk_add():
    items_to_add = [
        {"name": "A", "quantity": 5, "price": 1.00},
        {"name": "B", "quantity": 3, "price": 2.00},
        {"name": "C", "quantity": 7, "price": 3.00}
    ]
    added = bulk_add(items_to_add)
    assert len(added) == 3
    assert get_total_value() == 5*1 + 3*2 + 7*3

def test_export_import_json(tmp_path):
    add_item("Widget", 10, 5.99)
    filepath = str(tmp_path / "export.json")
    export_to_json(filepath)
    assert os.path.exists(filepath)
    reset()
    count = import_from_json(filepath)
    assert count == 1
    assert get_item("Widget") is not None
PYEOF
