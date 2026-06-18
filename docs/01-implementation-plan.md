# Ivra Implementation Plan

## Architecture

- Flutter app targets Android and web from one codebase.
- Supabase handles authentication, Postgres data, row-level security, server-side refill rules, approvals, and reporting views.
- The app uses a repository layer so screens can run against demo data first, then Supabase when credentials are provided.
- Offline support starts with a persistent local action queue for refill, undo, correction, and stock actions.
- QR code bottle scanning, product/photo images, and push notifications (Firebase Cloud Messaging) are supported in addition to in-app alerts.
- Localization covers English, French, Arabic (RTL), and Italian.

## Data Model

Core entities:

- Profiles and role assignments.
- Hotels, floors, rooms, and room products.
- Product catalog with localized labels, bottle/bidon sizes, max refill count, max bottle age, and stock thresholds.
- Hotel inventory per product.
- Refill events and correction requests.
- Approval requests for hotel manager edits.
- Audit log for accountability.
- Alerts and reporting views.

## Main Workflows

### Hotel Setup

App Admin/App Manager creates a hotel, floors, rooms, room templates, assigned products, and initial inventory.

### Hotel Manager Edits

Hotel Manager submits edits to hotel info, floors, rooms, or product assignments. The current production data does not change until App Manager/Admin approves the request.

### Refill Tracking

Hotel Manager or Staff records a product refill by room. The system increments refill count, updates last refill datetime, evaluates bottle age/refill limits, and raises alerts when needed.

### Undo And Correction

The user who recorded a refill can undo it within 30 minutes. After 30 minutes, they submit a correction request for App Manager/Admin review.

### Inventory And Orders

The app tracks 1L bottles and 5L bidons per hotel/product and calculates suggested reorder quantities. V1 does not create formal purchase orders.

### Reports

Admin/Manager can view and export product usage, refill history, low stock, recycling needs, suspicious activity, and suggested orders.

## Rollout

1. Build and verify demo-mode Flutter app.
2. Apply Supabase migration and seed products.
3. Connect Supabase credentials.
4. Test role permissions with real accounts.
5. Pilot with one hotel.
6. Expand to all hotels after report and alert accuracy is confirmed.

