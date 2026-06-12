import json

file_path = 'lib/src/data/supabase_ivra_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def find_method_range(method_name):
    start = -1
    end = -1
    brace_count = 0
    in_method = False
    
    for i, line in enumerate(lines):
        if not in_method:
            if 'Future<void> ' + method_name + '(' in line:
                start = i
                in_method = True
                brace_count += line.count('{') - line.count('}')
        else:
            brace_count += line.count('{') - line.count('}')
            if brace_count == 0:
                end = i
                return start, end
    return -1, -1

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
    'rejectRequest': ('Rejected change request', "{'request_id': approvalRequestId}"),
    'assignUserHotel': ('Assigned user to hotel', "{'user_id': userId, 'hotel_id': hotelId}"),
    'unassignUserHotel': ('Unassigned user from hotel', "{'user_id': userId, 'hotel_id': hotelId}"),
    'updateCurrentUserProfile': ('Updated current user profile', "{'full_name': fullName}"),
    'updateUserProfile': ('Updated user profile', "{'user_id': userId, 'full_name': fullName}"),
    'acceptTeamInvitation': ('Accepted team invitation', "{}"),
    'cancelTeamInvitation': ('Canceled team invitation', "{'invitation_id': invitationId}"),
    'resendTeamInvitation': ('Resent team invitation', "{'invitation_id': invitationId}")
}

chunks = []
for method, (action, details) in methods_to_patch.items():
    start, end = find_method_range(method)
    if start != -1:
        # Check if already patched
        original_text = ''.join(lines[start:end+1])
        if '_auditService.logAction' in original_text:
            continue
            
        # Add async before the opening brace of the method body
        # The method body brace is the LAST brace before 'return _client'
        
        new_text = original_text
        if 'return _client' in new_text:
            if ') {' in new_text:
                new_text = new_text.replace(') {', ') async {', 1)
            elif '}) {' in new_text:
                new_text = new_text.replace('}) {', '}) async {', 1)
            
            new_text = new_text.replace('return _client', 'await _client', 1)
            
        # insert logAction before the last brace
        last_brace_index = new_text.rfind('}')
        if last_brace_index != -1:
            log_code = f"    _auditService.logAction('{action}', details: {details});\n  "
            new_text = new_text[:last_brace_index] + log_code + new_text[last_brace_index:]
            
        chunks.append({
            'StartLine': start + 1,
            'EndLine': end + 1,
            'TargetContent': original_text,
            'ReplacementContent': new_text,
            'AllowMultiple': False
        })

print(json.dumps(chunks, indent=2))
