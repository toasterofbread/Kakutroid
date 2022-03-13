using Godot;
using System;
using System.Collections.Generic;

[Tool]
public class RoomTileMap : TileMap
{
	private Node Game;
	
	[Export] private bool init_on_ready = false;
	[Export] private int[] foreground_tiles = {};
	[Export] private int pulse_tile;
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
	
	private const String PULSE_TILE_NAME = "PULSE_TILE";
	public const int MAX_TILEMAP_SIZE = 10000;
	public const int MAX_PRIORITY = 100;
	public const int MAX_PULSE_AMOUNT = 5;
	public const int FRAMESKIP = 1;
	
	private TileMapData tilemap_data;
	private float camera_max_distance;
	private int skipped_frames = 0;
	
	private List<int> available_pulse_tiles = new List<int>();
	private List<RoomTileMapPulse>[] running_pulses = new List<RoomTileMapPulse>[MAX_PRIORITY + 1];
	private int running_pulse_count = 0;
	
	public bool Initialised = false;
	
	public void PulseBG(Vector2 origin, Color colour, bool force, int priority, float speed, float max_distance, float width) {
		
		Utils.assert(Initialised, "RoomTileMap must be initialised before use");
		Utils.assert(priority >= 0 && priority <= MAX_PRIORITY, "Invalid priority value");
		
		// If the current amount of pulses meets the maximum, don't create another pulse
		if (!force && MAX_PULSE_AMOUNT >= 0 && running_pulse_count >= MAX_PULSE_AMOUNT) {
			return;
		}
		
		// If max_distance is negative (infinite), use the camera_max_distance
		if (max_distance <= 0) {
			max_distance = camera_max_distance;
		}
		else {
			// Use camera_max_distance instead of max_distance if it is smaller
			max_distance = Math.Min(max_distance, camera_max_distance);
		}
		
		// Get the tile ID to be used for this pulse
		int tile;
		
		if (available_pulse_tiles.Count == 0) {
			// Create new pulse tile if none are available
			tile = CreateNewPulseTile(colour);
		}
		else {
			// Get the last available tile ID and remove it from the pool
			tile = available_pulse_tiles[available_pulse_tiles.Count - 1];
			available_pulse_tiles.RemoveAt(available_pulse_tiles.Count - 1);
			
			// Set the tile's modulate to the passed colour
			TileSet.TileSetModulate(tile, colour);
		}
		
		// Create new Pulse and add it to the pulse list
		if (running_pulses[priority] == null) {
			running_pulses[priority] = new List<RoomTileMapPulse>();
		}
		
		running_pulses[priority].Add(new RoomTileMapPulse(origin, tile, speed * 10.0F, max_distance, width));
		running_pulse_count += 1;
	}
	
	// Fills every empty tile within the TileMap's used rect with the passed type
	public void FillBackground(int tile_type) {
		Rect2 used_rect = GetUsedRect();
		
		for (int x = (int)used_rect.Position.x; x - used_rect.Position.x < used_rect.Size.x; x += 1) {
			for (int y = (int)used_rect.Position.y; y - used_rect.Position.y < used_rect.Size.y; y += 1) {
				
				int current_type = GetCell(x, y);
				
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
	
	public void SetCellvManual(Vector2 position, int tile) {
		SetCellManual((int)position.x, (int)position.y, tile);
	}
	
	public void SetCellManual(int x, int y, int tile) {
		tilemap_data.UpdateTile(x, y, tile);
		SetCell(x, y, tile);
	}
	
	public override void _Ready() {
		Game = GetNode("/root/Game");
		if (Engine.EditorHint || Game.Get("current_room") == null)
			return;
		
		ZIndex = 0;
		ZAsRelative = false;
		
		// Set the z_index of each tile according to whether it's a foreground or background tile
		var TileIds = TileSet.GetTilesIds();
		foreach (int Tile in TileIds) {
			if (!Array.Exists(foreground_tiles, element => element == Tile)) {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", 0));
//				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "BACKGROUND")));
			}
			else {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", 7));
//				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "WORLD")));
			}
		}
		
		if (init_on_ready)
			Init();
	}
	
	public void Init() {
		
		if (Initialised)
			return;
		
		// Generate and cache camera_max_distance and tilemap_data
		camera_max_distance = GetCameraMaxDistance(((Node)Game.Get("player")).Get("camera") as Camera2D) * 1.5F;
		tilemap_data = new TileMapData(this);
		
		// Add existing pulse tiles to the pool
		foreach (int tile in TileSet.GetTilesIds()) {
			if (TileSet.TileGetName(tile) == PULSE_TILE_NAME) {
				available_pulse_tiles.Add(tile);
			}
		}
		
		// Pre-create pulse tiles
		int precreate_amount = MAX_PULSE_AMOUNT - available_pulse_tiles.Count;
		for (int i = 0; i < precreate_amount; i += 1) {
			available_pulse_tiles.Add(CreateNewPulseTile(new Color()));
		}

		// Fill background if autofill_background_tile is set
		if (autofill_background_tile >= 0) {
			FillBackground(autofill_background_tile);
		}
		
		Initialised = true;
		
		// Begin pulse loop
		PulseProcessLoop();
	}
	
	private async void PulseProcessLoop() {
		Thread pulse_thread = new Thread();
		while (true) {
			float delta = (float)((await ToSignal(GetTree(), "idle_frame"))[0]);
			pulse_thread.Start(this, "ProcessPulse", delta);
			pulse_thread.WaitToFinish();
		}
	}
	
	private void ProcessPulse(float delta) {
		
		if (running_pulse_count == 0) {
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
			foreach (List<RoomTileMapPulse> priority in running_pulses) {
				if (priority == null)
					continue;
				foreach (RoomTileMapPulse pulse in priority) {
					float distance = pulse.Origin.DistanceTo(cell_pos);
					if (distance <= pulse.MaxDistance && Math.Abs(distance - pulse.CurrentDistance) <= pulse.Width) {
						target_type = pulse.Tile;
						break;
					}
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
		
		foreach (List<RoomTileMapPulse> priority in running_pulses) {
			if (priority == null)
				continue;
			for (int i = 0; i < priority.Count; i += 1) {
				RoomTileMapPulse pulse = priority[i];
				
				// Remove pulse if completed
				if (pulse.Completed) {
					
					// Return the pulse's tile ID to the available tile pool
					available_pulse_tiles.Add(pulse.Tile);
					
					priority.RemoveAt(i);
					running_pulse_count -= 1;
					i -= 1;
				}
				else {
					
					// Progress pulse current distance by its speed, accounting for frameskip
					pulse.CurrentDistance += pulse.Speed * (float)(FRAMESKIP + 1) * delta;
					
					if (pulse.CurrentDistance > pulse.MaxDistance + pulse.Width) {
						
						// Flag pulse to be removed on the next frame
						// Removing it on this frame would leave uncleared pulse tiles
						pulse.Completed = true;
					}
				}
			}
		}
	}
	
	// Creates a new pulse tile with passed colour and returns the ID
	private int CreateNewPulseTile(Color colour) {
		int tile = TileSet.GetLastUnusedTileId();
		TileSet.DuplicateTile(pulse_tile, tile);
		TileSet.TileSetModulate(tile, colour);
		TileSet.TileSetName(tile, PULSE_TILE_NAME);
		return tile;
	}
	
	private float GetCameraMaxDistance(Camera2D camera) {
		Vector2 view_size = GetViewportRect().Size / GetCanvasTransform().Scale;
		return (float)(Math.Sqrt(Math.Pow(view_size.x / 2.0F, 2.0F) + Math.Pow(view_size.y / 2.0F, 2.0F)));
	}
	
	// Contains data about a running pulse
	private class RoomTileMapPulse {
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
			Speed = speed * 60.0F;
			MaxDistance = max_distance;
			Width = width;
		}
	}
	
	// Stores the values of every tile on a given tilemap
	private class TileMapData: Reference {
		
		private TileMap tilemap;
		private int[,] data = null;
		private int offset_x;
		private int offset_y;
		
		public TileMapData(TileMap tilemap) {
			this.tilemap = tilemap;
			UpdateAll();
		}
		
		public void UpdateAll() {
			Rect2 used_rect = tilemap.GetUsedRect();
			
			if (data == null || used_rect.Size.x >= MAX_TILEMAP_SIZE || used_rect.Size.y >= MAX_TILEMAP_SIZE)
				data = new int[(int)used_rect.Size.x, (int)used_rect.Size.y];
			
			offset_x = (int)used_rect.Position.x;
			offset_y = (int)used_rect.Position.y;
			for (int x = 0; x < used_rect.Size.x; x += 1) {
				for (int y = 0; y < used_rect.Size.y; y += 1) {
					data[x, y] = tilemap.GetCell(x + offset_x, y + offset_y);
				}
			}
		}
		
		public void UpdateTile(int x, int y, int tile) {
			data[x - offset_x, y - offset_y] = tile;
		}
		
		public void UpdateTilev(Vector2 position, int tile) {
			UpdateTile((int)position.x, (int)position.y, tile);
		}
		
		public int GetTile(int x, int y) {
			return data[x - offset_x, y - offset_y];
		}
		
		public int GetTilev(Vector2 position) {
			return GetTile((int)position.x, (int)position.y);
		}
	}
}
