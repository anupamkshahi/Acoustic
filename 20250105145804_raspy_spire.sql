/*
  # Initial Schema Setup for Acoustic Music Platform

  1. New Tables
    - users (handled by Supabase Auth)
    - artists
      - id (uuid, primary key)
      - name (text)
      - biography (text)
      - genre (text[])
      - image_url (text)
      - created_at (timestamp)
    - songs
      - id (uuid, primary key)
      - title (text)
      - artist_id (uuid, foreign key)
      - album (text)
      - genre (text[])
      - duration (integer)
      - cover_url (text)
      - audio_url (text)
      - created_at (timestamp)
    - playlists
      - id (uuid, primary key)
      - name (text)
      - user_id (uuid, foreign key)
      - created_at (timestamp)
    - playlist_songs
      - playlist_id (uuid, foreign key)
      - song_id (uuid, foreign key)
      - added_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Artists table
CREATE TABLE artists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  biography text,
  genre text[] DEFAULT '{}',
  image_url text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE artists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Artists are viewable by everyone"
  ON artists FOR SELECT
  TO authenticated
  USING (true);

-- Songs table
CREATE TABLE songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  artist_id uuid REFERENCES artists(id),
  album text,
  genre text[] DEFAULT '{}',
  duration integer NOT NULL,
  cover_url text,
  audio_url text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Songs are viewable by everyone"
  ON songs FOR SELECT
  TO authenticated
  USING (true);

-- Playlists table
CREATE TABLE playlists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create their own playlists"
  ON playlists FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own playlists"
  ON playlists FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Playlist songs junction table
CREATE TABLE playlist_songs (
  playlist_id uuid REFERENCES playlists(id) ON DELETE CASCADE,
  song_id uuid REFERENCES songs(id) ON DELETE CASCADE,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (playlist_id, song_id)
);

ALTER TABLE playlist_songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can add songs to their playlists"
  ON playlist_songs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM playlists
      WHERE id = playlist_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view songs in their playlists"
  ON playlist_songs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM playlists
      WHERE id = playlist_id
      AND user_id = auth.uid()
    )
  );