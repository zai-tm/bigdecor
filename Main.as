CGameCtnDecorationSize@ g_decorSize = null;
nat3 g_originalSize;

CreateUI g_createUI;

void OnEditorOpen()
{
}

void OnEditorClose()
{
	if (g_decorSize !is null) {
		g_decorSize.SizeX = g_originalSize.x;
		g_decorSize.SizeY = g_originalSize.y;
		g_decorSize.SizeZ = g_originalSize.z;
		@g_decorSize = null;
	}
}

void Main()
{
	auto app = cast<CGameManiaPlanet>(GetApp());

	bool inMapEditor = false;

	while (true) {
		g_createUI.Update();
		yield();

		auto editor = cast<CGameCtnEditorFree>(app.Editor);
		if (!inMapEditor && editor !is null) {
			inMapEditor = true;
			OnEditorOpen();
		} else if (inMapEditor && editor is null) {
			inMapEditor = false;
			OnEditorClose();
		}
	}
}

void RenderMenu()
{
	bool canOpenAdvancedEditor = Permissions::OpenAdvancedMapEditor();
	if (UI::MenuItem("\\$cf9" + Icons::Map + "\\$z Create a new map", "", g_createUI.m_visible, canOpenAdvancedEditor) && !g_createUI.m_visible) {
		g_createUI.m_visible = !g_createUI.m_visible;
	}
}

void RenderInterface()
{
	g_createUI.Render();
}
