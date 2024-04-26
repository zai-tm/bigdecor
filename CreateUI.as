class CreateUI
{
	bool m_visible = false;

	string m_stadiumType = "Base";
	array<string> m_stadiumTypes = {
		"Base",
		"NoStadium"
	};

	string m_stadiumBase = "48x48";
	array<string> m_stadiumBases = {
		"48x48"
	};

	array<string> m_moods = {
		"Screen155Sunrise",
		"Screen155Day",
		"Screen155Sunset",
		"Screen155Night"
	};

	string m_currentEnviro;
	string m_currentCar;
	string m_currentMood = m_moods[1];
	string m_currentMod;

	array<string> m_environments;
	array<string> m_archetypes;
	array<string> m_mods;

	int m_decoSizeX;
	int m_decoSizeY;
	int m_decoSizeZ;
	int m_decoGroundY;
	int m_decoSizeStep = 16;

	CGameManiaTitle@ m_title;

	void Render()
	{
		if (!m_visible) {
			return;
		}

		auto app = GetApp();

		UI::Begin("Create a new map", m_visible, UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse);

		if (m_environments.Length <= 0 || m_archetypes.Length <= 0) {
			// Not in a pack
			UI::Text("Enter a title pack before trying to create a new map.");

		} else if (app.RootMap !is null) {
			// A map is loaded
			UI::Text("Return to the main menu to create a new map.");

		} else {
			// Ready to create a new map
			UI::Text("Environment");

			// Environment
			if (UI::BeginCombo("Environment", m_currentEnviro)) {
				for (uint i = 0; i < m_environments.Length; i++) {
					string environment = m_environments[i];

					if (UI::Selectable(environment, environment == m_currentEnviro)) {
						SetEnvironment(environment);
					}
				}

				UI::EndCombo();
			}

			// Archetype
			if (UI::BeginCombo("Gameplay", m_currentCar)) {
				for (uint i = 0; i < m_archetypes.Length; i++) {
					string archetype = m_archetypes[i];
					if (UI::Selectable(archetype, archetype == m_currentCar)) {
						m_currentCar = archetype;
					}
				}
				UI::EndCombo();
			}

			// Mod
			if (m_mods.Length > 0) {
				if (UI::BeginCombo("Mod", m_currentMod)) {
					if (UI::Selectable("(none)", m_currentMod == "")) {
						m_currentMod = "";
					}
					for (uint i = 0; i < m_mods.Length; i++) {
						string mod = m_mods[i];
						if (UI::Selectable(mod, mod == m_currentMod)) {
							m_currentMod = mod;
						}
					}
					UI::EndCombo();
				}
			}

			UI::Text("Decoration properties");

			// Stadium decoration type
			if (m_currentEnviro == "Stadium") {
				if (UI::BeginCombo("Base", m_stadiumBase)) {
					for (uint i = 0; i < m_stadiumBases.Length; i++) {
						string stadiumBase = m_stadiumBases[i];
						if (UI::Selectable(stadiumBase, stadiumBase == m_stadiumBase)) {
							m_stadiumBase = stadiumBase;
							UpdateSizeSettings();
						}
					}
					UI::EndCombo();
				}
			}

			// Mood
			if (UI::BeginCombo("Mood", m_currentMood)) {
				for (uint i = 0; i < m_moods.Length; i++) {
					string mood = m_moods[i];
					if (UI::Selectable(mood, mood == m_currentMood)) {
						m_currentMood = mood;
					}
				}
				UI::EndCombo();
			}

			// Dimensions
			if (m_decoSizeX <= 0) { m_decoSizeX = m_decoSizeStep; }
			if (m_decoSizeY <= 0) { m_decoSizeY = m_decoSizeStep; }
			if (m_decoSizeZ <= 0) { m_decoSizeZ = m_decoSizeStep; }

			m_decoSizeX = UI::InputInt("Size X", m_decoSizeX, m_decoSizeStep);
			m_decoSizeY = UI::InputInt("Size Y (height)", m_decoSizeY, m_decoSizeStep);
			m_decoSizeZ = UI::InputInt("Size Z", m_decoSizeZ, m_decoSizeStep);

			// Limitation of the engine
			if (m_decoSizeX > 255) { m_decoSizeX = 255; }
			if (m_decoSizeY > 255) { m_decoSizeY = 255; }
			if (m_decoSizeZ > 255) { m_decoSizeZ = 255; }

			// Ground height
			//if (m_decoGroundY < 0) m_decoGroundY = 0;
			//m_decoGroundY = UI::InputInt("Ground Y", m_decoGroundY, 1);

			// Create
			if (UI::Button("Create")) {
				m_visible = false;
				EditNewMap();
			}
			UI::SameLine();
		}

		if (UI::Button("Close")) {
			m_visible = false;
		}

		UI::End();
	}

	void SetEnvironment(const string &in enviro)
	{
		m_currentEnviro = enviro;

		if (m_currentEnviro == "Stadium") { m_currentCar = "CarSport"; }

		UpdateSizeSettings();
		SetMods();
	}

	void UpdateSizeSettings()
	{
		m_decoSizeY = 40;

		if (m_currentEnviro == "Stadium") {
			m_decoSizeX = 48;
			m_decoGroundY = 8;
		}

		m_decoSizeZ = m_decoSizeX;
	}

	void EditNewMap()
	{
		CTrackMania@ app = cast<CTrackMania>(GetApp());

		if (app.ManiaTitleControlScriptAPI is null) {
			return;
		}

		@g_decorSize = null;

		CGameCtnDecoration@ deco = null;

		auto fidDeco = Fids::GetGame("GameData/Stadium/GameCtnDecoration/" + m_stadiumType + m_stadiumBase + m_currentMood + ".Decoration.Gbx");
		if (fidDeco !is null) {
			@deco = cast<CGameCtnDecoration>(Fids::Preload(fidDeco));
			if (deco is null) {
				error("Unable to load decor for base '" + m_stadiumType + "' with '" + m_stadiumBase + "' and mood '" + m_currentMood + "'!");
				return;
			}
		} else {
			error("Unable to find decor for base '" + m_stadiumType + "' with '" + m_stadiumBase + "' and mood '" + m_currentMood + "'!");
			return;
		}

		@g_decorSize = deco.DecoSize;

		g_originalSize.x = g_decorSize.SizeX;
		g_originalSize.y = g_decorSize.SizeY;
		g_originalSize.z = g_decorSize.SizeZ;

		print("Setting decor size");

		g_decorSize.SizeX = m_decoSizeX;
		g_decorSize.SizeY = m_decoSizeY;
		g_decorSize.SizeZ = m_decoSizeZ;
		//g_decorSize.BaseHeightOffset = m_decoGroundY;

		string modPath = "";
		if (m_currentMod != "") {
			modPath = "Skins/" + m_currentEnviro + "/Mod/" + m_currentMod;
		}

		print("Starting editor");

		app.ManiaTitleControlScriptAPI.EditNewMap2(
			m_currentEnviro,
			m_stadiumBase + m_currentMood,
			modPath,
			m_currentCar,
			"", false, "", ""
		);
	}

	void Update()
	{
		if (!m_visible) {
			@m_title = null;
			return;
		}

		auto app = cast<CGameManiaPlanet>(GetApp());

		if (m_title !is app.LoadedManiaTitle) {
			@m_title = app.LoadedManiaTitle;
			UpdateInfo();
		}
	}

	void SetMods()
	{
		string skinsPath = "Skins/" + m_currentEnviro + "/Mod";

		m_mods.RemoveRange(0, m_mods.Length);

		AddMods(Fids::GetUserFolder(skinsPath));

		auto folderTitles = Fids::GetFakeFolder("Titles");
		if (folderTitles !is null) {
			for (uint j = 0; j < folderTitles.Trees.Length; j++) {
				AddMods(Fids::GetFidsFolder(folderTitles.Trees[j], skinsPath));
			}
		}

		m_currentMod = "";
	}

	void AddMods(CSystemFidsFolder@ folder)
	{
		if (folder is null) {
			return;
		}

		for (uint i = 0; i < folder.Leaves.Length; i++) {
			auto fidMod = folder.Leaves[i];
			m_mods.InsertLast(fidMod.FileName);
		}
	}

	void UpdateInfo()
	{
		m_environments.RemoveRange(0, m_environments.Length);
		m_archetypes.RemoveRange(0, m_archetypes.Length);

		for (uint i = 0; i < m_title.CollectionFids.Length; i++) {
			auto fid = cast<CSystemFidFile>(m_title.CollectionFids[i]);

			if (fid.ShortFileName == "Stadium" || fid.ShortFileName == "StadiumCE") {
				m_environments.InsertLast("Stadium");
				m_archetypes.InsertLast("CarSport");
				m_archetypes.InsertLast("CarSnow");
				m_archetypes.InsertLast("CarRally");
				m_archetypes.InsertLast("CarDesert");
				m_archetypes.InsertLast("CharacterPilot");
			}

			SetEnvironment(m_environments[0]);
		}
	}
}
