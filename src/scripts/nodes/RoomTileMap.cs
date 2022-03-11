using Godot;
using System;
using System.Collections.Generic;

[Tool]
public class RoomTileMap : TileMap
{
	const int MAX_TILEMAP_SIZE = 10000;
	private Node Game;
	
	[Export] private int[] foreground_tiles = {};
	[Export] private int autofill_background_tile = -1;
	[Export] private bool autofill_now {
		get { return false; }
		set {
			if (value)
				if (autofill_background_tile <= 0)
					GD.Print("autofill_background_tile is not set");
				else
					FillBackground(autofill_background_tile);
					GD.Print("Autofill completed");
		}
	}
//	[Export] private bool add_collision_to_autofill {
//		get { return false; }
//		set {
//			if (value)
//				if (autofill_background_tile <= 0)
//					GD.Print("autofill_background_tile is not set");
//				else
//					for (int x = 0; x < 12; x += 1) {
//						for (int y = 0; y < 4; y += 1) {
//							ConvexPolygonShape2D shape = new ConvexPolygonShape2D();
//							shape.Points = new Vector2[]{
//								new Vector2(0, 0),
//								new Vector2(0, 18),
//								new Vector2(18, 18),
//								new Vector2(18, 0)
//							};
//							TileSet.TileAddShape(0, shape, new Transform2D(0.0F, new Vector2(0, 0)), false, new Vector2(12, 4));
//						}
//					}
//		}
//	}
	
	private TileMapData tilemap_data;
	
	public enum BG_COLOUR {
		NORMAL
	}
	private const int BG_DEFAULT = 1;
	private const float INF = Godot.Mathf.Inf;
	
	private List<RoomTileMapPulse> pulses = new List<RoomTileMapPulse>();
	
	private const int MAX_PULSE_AMOUNT = 5;
	private const int FRAMESKIP = 1;
	private int skipped_frames = 0;
	
	private float camera_max_distance;
	
	public void PulseBG(Vector2 origin, int tile, float speed, float max_distance, float width) {
		
		Utils.assert(tile >= 0);
		
		if (MAX_PULSE_AMOUNT >= 0 && pulses.Count >= MAX_PULSE_AMOUNT) {
			return;
		}
		
		if (max_distance <= 0) {
			max_distance = camera_max_distance;
		}
		else {
			max_distance = Math.Min(max_distance, camera_max_distance);
		}
		
		pulses.Add(new RoomTileMapPulse(origin, tile, speed * 10.0F, max_distance, width));
	}
	
	
	public void FillBackground(int tile_type) {
		Rect2 used_rect = GetUsedRect();
		
		for (int x = (int)used_rect.Position.x; x - used_rect.Position.x < used_rect.Size.x; x += 1) {
			for (int y = (int)used_rect.Position.y; y - used_rect.Position.y < used_rect.Size.y; y += 1) {
				
				int current_type = GetCell(x, y);
				
//				// Skip cell if it's a foreground tile
//				if (current_type >= 0 && Array.Exists(foreground_tiles, element => element == current_type)) {
//					continue;
//				}

				// Skip cell if not empty
				if (current_type != -1)
					continue;
				
				// Update cell if the target type is different
				if (tile_type != current_type) {
					SetCell(x, y, tile_type);
					UpdateBitmaskArea(new Vector2(x, y));
				}
			}
		}
	}
	
	public override void _Ready() {
		
		if (Engine.EditorHint)
			return;
		
		Game = GetNode("/root/Game");
		camera_max_distance = GetCameraMaxDistance(((Node)Game.Get("player")).Get("camera") as Camera2D) * 1.5F;
		
		ZIndex = 0;
		ZAsRelative = false;
		
		tilemap_data = new TileMapData(this);
		
		var TileIds = TileSet.GetTilesIds();
		foreach (int Tile in TileIds) {
			if (!Array.Exists(foreground_tiles, element => element == Tile)) {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "BACKGROUND")));
			}
			else {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "WORLD")));
			}
		}
		
		if (autofill_background_tile >= 0) {
			FillBackground(autofill_background_tile);
		}
		
		PulseProcessLoop();
	}
	
	private async void PulseProcessLoop() {
//		Thread pulse_thread = new Thread();
		while (true) {
//			pulse_thread.Start(this, "ProcessPulse");
//			pulse_thread.WaitToFinish();
			ProcessPulse();
			await ToSignal(GetTree(), "idle_frame");
		}
	}
	
	private void ProcessPulse() {
		
		if (pulses.Count == 0) {
			skipped_frames = FRAMESKIP;
			return;
		}
		
		if (skipped_frames < FRAMESKIP) {
			skipped_frames += 1;
			return;
		}
		skipped_frames = 0;
		
		foreach (Vector2 cell in GetUsedCells()) {
			int current_type = GetCellv(cell);
			
			// Skip cell if it's a foreground tile
			if (current_type >= 0 && Array.Exists(foreground_tiles, element => element == current_type)) {
				continue;
			}
			
			// Get global position of cell
			Vector2 cell_pos = ToGlobal(MapToWorld(cell));
			
			// Iterate through each pulse until one changes this cell's type
			int target_type = -1;
			foreach (RoomTileMapPulse pulse in pulses) {
				float distance = pulse.Origin.DistanceTo(cell_pos);
				if (distance <= pulse.MaxDistance && Math.Abs(distance - pulse.CurrentDistance) <= pulse.Width) {
					target_type = pulse.Tile;
					break;
				}
			}
			
			if (target_type == -1) {
				target_type = tilemap_data.GetTilev(cell);
			}
			
			// Update cell if the type changed
			if (target_type != current_type) {
				SetCellv(cell, target_type);
				UpdateBitmaskArea(cell);
			}
		}
		
		for (int i = 0; i < pulses.Count; i += 1) {
			RoomTileMapPulse pulse = pulses[i];
			
			// Remove pulse if completed
			if (pulse.Completed) {
				pulses.RemoveAt(i);
				i -= 1;
			}
			else {
				// Progress pulse current distance by its speed
				pulse.CurrentDistance += pulse.Speed * (float)(FRAMESKIP + 1);
				
				if (pulse.CurrentDistance > pulse.MaxDistance + pulse.Width) {
					
					// Flag pulse to be removed on the next frame
					pulse.Completed = true;
				}
			}
		}
	}
	
	private float GetCameraMaxDistance(Camera2D camera) {
		Vector2 view_size = GetViewportRect().Size / GetCanvasTransform().Scale;
		return (float)(Math.Sqrt(Math.Pow(view_size.x / 2.0F, 2.0F) + Math.Pow(view_size.y / 2.0F, 2.0F)));
	}
	
	// Contains data about a running pulse
	private class RoomTileMapPulse: Reference {
		public Vector2 Origin;
		public int Tile;
		public float Speed;
		public float MaxDistance;
		public float Width;
		public float CurrentDistance = 0.0F;
		
		public bool Completed = false;
		
		public RoomTileMapPulse(Vector2 origin, int tile, float speed, float max_distance, float width) {
			Origin = origin;
			Tile = tile;
			Speed = speed;
			MaxDistance = max_distance;
			Width = width;
		}
	}
	
	// Stores the values of every tile on a given tilemap
	private class TileMapData: Reference {
		
		private TileMap tilemap;
		private int[,] data = new int[MAX_TILEMAP_SIZE, MAX_TILEMAP_SIZE];
		private int offset_x;
		private int offset_y;
		
		public TileMapData(TileMap tilemap) {
			this.tilemap = tilemap;
			Update();
		}
		
		public void Update() {
			Rect2 used_rect = tilemap.GetUsedRect();
			offset_x = (int)used_rect.Position.x;
			offset_y = (int)used_rect.Position.y;
			for (int x = 0; x < used_rect.Size.x; x += 1) {
				for (int y = 0; y < used_rect.Size.y; y += 1) {
					data[x, y] = tilemap.GetCell(x + offset_x, y + offset_y);
				}
			}
		}
		
		public int GetTile(int x, int y) {
			return data[x - offset_x, y - offset_y];
		}
		
		public int GetTilev(Vector2 position) {
			return GetTile((int)position.x, (int)position.y);
		}
	}
}
