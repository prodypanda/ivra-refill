import re

file_path = 'lib/src/data/supabase_ivra_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

def replace_with_log(match, action_name, log_details='{}'):
    params = match.group(1)
    body = match.group(2)
    # If it's a direct return _client...
    if 'return _client' in body and 'async' not in params:
        # Convert to async
        new_params = params.replace(') {', ') async {')
        new_body = body.replace('return _client', 'await _client')
        # Extract the last bracket or semi-colon
        new_body = new_body.replace(';\n  }', f";\n    _auditService.logAction('{action_name}', details: {log_details});\n  }}")
        return match.group(0).replace(params + body, new_params + new_body)
    elif 'await _client' in body:
        # Just insert before the end
        new_body = body.replace(';\n  }', f";\n    _auditService.logAction('{action_name}', details: {log_details});\n  }}")
        return match.group(0).replace(body, new_body)
    return match.group(0)

# Replace specific methods
methods_to_patch = {
    'createHotel': ('Created hotel', "{'name': name}"),
    'deleteHotel': ('Deleted hotel', "{'hotel_id': hotelId}"),
    'deleteRoom': ('Deleted room', "{'room_id': roomId}"),
    'deleteFloor': ('Deleted floor', "{'floor_id': floorId}"),
    'deleteUser': ('Deleted user', "{'user_id': userId}"),
    'deleteAlert': ('Deleted alert', "{'alert_id': alertId}"),
    'deleteProduct': ('Deleted product', "{'product_id': productId}"),
    'createRoomsFromTemplate': ('Created rooms from template', "{'hotel_id': hotelId, 'floor_number': floorNumber, 'room_count': roomCount}"),
    'createProduct': ('Created product', "{'sku': sku}"),
    'updateProduct': ('Updated product', "{'product_id': productId}"),
    'recordRefill': ('Recorded refill', "{'room_product_id': roomProductId}"),
    'undoRefill': ('Undid refill', "{'refill_event_id': refillEventId}"),
    'requestCorrection': ('Requested stock correction', "{'refill_event_id': refillEventId}"),
    'replaceBottle': ('Replaced bottle', "{'room_product_id': roomProductId}"),
    'recordStockAdjustment': ('Recorded stock adjustment', "{'hotel_id': hotelId, 'product_id': productId}"),
    'rejectRequest': ('Rejected change request', "{'request_id': approvalRequestId}"),
    'assignUserHotel': ('Assigned user to hotel', "{'user_id': userId, 'hotel_id': hotelId}"),
    'unassignUserHotel': ('Unassigned user from hotel', "{'user_id': userId, 'hotel_id': hotelId}")
}

for method, (action, details) in methods_to_patch.items():
    pattern = r'(Future<void> ' + method + r'\([^)]*\)(?: async)? \{)([^}]+})'
    match = re.search(pattern, content)
    if match:
        content = content[:match.start()] + replace_with_log(match, action, details) + content[match.end():]

# Handle submitChangeRequest separately
pattern = r'(Future<String\?> submitChangeRequest\([^)]*\)(?: async)? \{)([^}]+})'
match = re.search(pattern, content)
if match:
    params = match.group(1)
    body = match.group(2)
    new_params = params.replace(') {', ') async {')
    new_body = body.replace('return _client', 'final result = await _client').replace('.then((value) => value?.toString());', '.then((value) => value?.toString());\n    _auditService.logAction(\'Submitted change request\', details: {\'target_table\': targetTable, \'target_id\': targetId});\n    return result;')
    content = content[:match.start()] + new_params + new_body + content[match.end():]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched methods!")
