import 'package:powersync/powersync.dart';

// Schema definition for offline sync
const schema = Schema([
  // ANNOUNCEMENTS
  Table('announcements', [
    Column.text('title'),
    Column.text('content'),
    Column.text('image_url'), // Optional thumbnail
    Column.text('created_by'), // UUID of creator
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.integer('is_pinned'), // 0 or 1
  ]),

  // NEWS
  Table('news', [
    Column.text('title'),
    Column.text('content'),
    Column.text('image_url'),
    Column.text('category'), // e.g., 'sports', 'local'
    Column.text('created_by'),
    Column.text('created_at'),
    Column.integer('is_published'),
  ]),

  // ORGANIZATIONS
  Table('organizations', [
    Column.text('name'),
    Column.text('type'), // 'council', 'ngo', 'church', 'institution'
    Column.text('parent_id'), // For tree structure
    Column.text('logo_url'),
    Column.text('contact_phone'),
    Column.text('description'),
    Column.text('current_term'), // e.g., "2025-2026"
  ]),

  // OFFICE BEARERS (Members of organizations)
  Table('office_bearers', [
    Column.text('org_id'),
    Column.text('name'),
    Column.text('position'), // 'President', 'Secretary'
    Column.text('phone'),
    Column.text('photo_url'),
    Column.integer('rank_order'), // For sorting
  ]),

  // DIGITAL BOOK (Stories/Chapters)
  Table('books', [
    Column.text('title'),
    Column.text('author'),
    Column.text('cover_url'),
    Column.text('description'),
  ]),

  Table('chapters', [
    Column.text('book_id'),
    Column.text('title'),
    Column.text('content'), // HTML or Markdown
    Column.integer('chapter_number'),
    Column.text('updated_at'),
  ]),

  // PROFILES (Users)
  Table('profiles', [
    Column.text('email'),
    Column.text('full_name'),
    Column.text('phone_number'),
    Column.text('dob'), // ISO string
    Column.text('address'),
    Column.text('role'), // 'guest', 'user', 'editor', 'admin'
    Column.text('avatar_url'),
  ]),
]);
