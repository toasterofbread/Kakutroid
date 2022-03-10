using Godot;
using System;
using System.Collections.Generic;

public class RoomTileMap : TileMap
{
	private Node Game;
	
	private int[] BG_TILES = {1, 2};
	private enum BG_COLOUR {
		NORMAL
	}
	private const int BG_DEFAULT = 1;
	private const float INF = Godot.Mathf.Inf;
	
	private List<RoomTileMapPulse> pulses = new List<RoomTileMapPulse>();
	
	private const int MAX_PULSE_AMOUNT = -1;
	private const int FRAMESKIP = 0;
	private int skipped_frames = 0;
	
	private float camera_max_distance;
	
	public void PulseBg(Vector2 origin, float speed = 1, float max_distance = -1, float width = 50) {
		
		if (MAX_PULSE_AMOUNT >= 0 && pulses.Count >= MAX_PULSE_AMOUNT) {
			return;
		}
		
		if (max_distance <= 0) {
			max_distance = camera_max_distance;
		}
		else {
			max_distance = Math.Min(max_distance, camera_max_distance);
		}
		
		pulses.Add(new RoomTileMapPulse(origin, speed * 10.0F, max_distance, width));
	}
	
	public override void _Ready() {
		Game = GetNode("/root/Game");
		camera_max_distance = GetCameraMaxDistance(((Node)Game.Get("player")).Get("camera") as Camera2D) * 1.5F;
		
		ZIndex = 0;
		ZAsRelative = false;
		
		TileSet.TileSetModulate(0, Modulate);
		Modulate = new Color(1, 1, 1, 1);
		
		var TileIds = TileSet.GetTilesIds();
		foreach (int Tile in TileIds) {
			if (Array.Exists(BG_TILES, element => element == Tile)) {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "BACKGROUND")));
			}
			else {
				TileSet.TileSetZIndex(Tile, (int)Game.Call("get_layer_z_index", Game.Call("get_layer_by_name", "WORLD")));
			}
		}
		PulseProcessLoop();
	}
	
	private async void PulseProcessLoop() {
		Thread pulse_thread = new Thread();
		while (true) {
			pulse_thread.Start(this, "ProcessPulse");
			pulse_thread.WaitToFinish();
			await ToSignal(GetTree(), "idle_frame");
		}
	}
	
	public void ProcessPulse() {
		
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
			
			// Skip cell if it isn't a background tile
			if (!Array.Exists(BG_TILES, element => element == current_type)) {
				continue;
			}
			
			// Get global position of cell
			Vector2 cell_pos = ToGlobal(MapToWorld(cell));
			
			// Iterate through each pulse until one changes this cell's type
			int target_type = BG_DEFAULT;
			foreach (RoomTileMapPulse pulse in pulses) {
				float distance = pulse.Origin.DistanceTo(cell_pos);
				if (distance <= pulse.MaxDistance && Math.Abs(distance - pulse.CurrentDistance) <= pulse.Width) {
					target_type = 2;
					break;
				}
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
				pulse.CurrentDistance += pulse.Speed;
				
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
		public float Speed;
		public float MaxDistance;
		public float Width;
		public float CurrentDistance = 0.0F;
		
		public bool Completed = false;
		
		public RoomTileMapPulse(Vector2 origin, float speed, float max_distance, float width) {
			Origin = origin;
			Speed = speed;
			MaxDistance = max_distance;
			Width = width;
		}
	}
}
