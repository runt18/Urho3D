// Urho2D physics sample.
// This sample demonstrates:
//     - Creating both static and moving 2D physics objects to a scene
//     - Displaying physics debug geometry

#include "Scripts/Utilities/Sample.as"

Scene@ scene_;
Node@ cameraNode;

void Start()
{
    // Execute the common startup for samples
    SampleStart();

    // Create the scene content
    CreateScene();

    // Create the UI content
    CreateInstructions();

    // Setup the viewport for displaying the scene
    SetupViewport();

    // Hook up to the frame update events
    SubscribeToEvents();
}

void CreateScene()
{
    scene_ = Scene();

    // Create the Octree component to the scene. This is required before adding any drawable components, or else nothing will
    // show up. The default octree volume will be from (-1000, -1000, -1000) to (1000, 1000, 1000) in world coordinates; it
    // is also legal to place objects outside the volume but their visibility can then not be checked in a hierarchically
    // optimizing manner
    scene_.CreateComponent("Octree");
    scene_.CreateComponent("DebugRenderer");

    // Create a scene node for the camera, which we will move around
    // The camera will use default settings (1000 far clip distance, 45 degrees FOV, set aspect ratio automatically)
    cameraNode = scene_.CreateChild("Camera");
    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 0.0f, -10.0f);

    Camera@ camera = cameraNode.CreateComponent("Camera");
    camera.orthographic = true;

    uint width = graphics.width * PIXEL_SIZE;
    uint height = graphics.height * PIXEL_SIZE;
    camera.SetOrthoSize(Vector2(width, height));

    // Create 2D physics world component
    scene_.CreateComponent("PhysicsWorld2D");
    
    // Create ground.
    Node@ groundNode = scene_.CreateChild("Ground");
    groundNode.position = Vector3(0.0f, -3.0f, 0.0f);
    groundNode.scale = Vector3(200.0f, 1.0f, 0.0f);
    
    // Create 2D rigid body for gound
    RigidBody2D@ groundBody = groundNode.CreateComponent("RigidBody2D");
    
    // Create box collider for ground
    CollisionBox2D@ groundShape = groundNode.CreateComponent("CollisionBox2D");
    // Set box size
    groundShape.size = Vector2(0.1f, 0.1f);
    // Set friction
    groundShape.friction = 0.5f;

    const uint NUM_OBJECTS = 100;
    for (uint i = 0; i < NUM_OBJECTS; ++i)
    {
        Node@ node  = scene_.CreateChild("RigidBody");
        node.position = Vector3(Random(-0.1f, 0.1f), 5.0f + i * 0.4f, 0.0f);

        // Create rigid body
        RigidBody2D@ body = node.CreateComponent("RigidBody2D");
        body.bodyType = BT_DYNAMIC;

        if (i % 2 == 0)
        {
            // Create box
            CollisionBox2D@ box = node.CreateComponent("CollisionBox2D");
            // Set size
            box.size = Vector2(0.32f, 0.32f);
            // Set density
            box.density = 1.0f;
            // Set friction
            box.friction = 0.5f;
            // Set restitution
            box.restitution = 0.1f;
        }
        else
        {
            // Create circle
            CollisionCircle2D@ circle = node.CreateComponent("CollisionCircle2D");
            // Set radius
            circle.radius = 0.16f;
            // Set density
            circle.density = 1.0f;
            // Set friction.
            circle.friction = 0.5f;
            // Set restitution
            circle.restitution = 0.1f;
        }
    }
}

void CreateInstructions()
{
    // Construct new Text object, set string to display and font to use
    Text@ instructionText = ui.root.CreateChild("Text");
    instructionText.text = "Use WASD keys and mouse to move, Use PageUp PageDown to zoom.";
    instructionText.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15);

    // Position the text relative to the screen center
    instructionText.horizontalAlignment = HA_CENTER;
    instructionText.verticalAlignment = VA_CENTER;
    instructionText.SetPosition(0, ui.root.height / 4);
}

void SetupViewport()
{
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    // at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    // use, but now we just use full screen and default render path configured in the engine command line options
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
}

void MoveCamera(float timeStep)
{
    // Do not move if the UI has a focused element (the console)
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    const float MOVE_SPEED = 4.0f;
    
    // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
    // Use the TranslateRelative() function to move relative to the node's orientation. Alternatively we could
    // multiply the desired direction with the node's orientation quaternion, and use just Translate()
    if (input.keyDown['W'])
        cameraNode.TranslateRelative(Vector3(0.0f, 1.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.TranslateRelative(Vector3(0.0f, -1.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.TranslateRelative(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.TranslateRelative(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);

    if (input.keyDown[KEY_PAGEUP])
    {
        Camera@ camera = cameraNode.GetComponent("Camera");
        camera.zoom = camera.zoom * 1.01f;
    }
    
    if (input.keyDown[KEY_PAGEDOWN])
    {
        Camera@ camera = cameraNode.GetComponent("Camera");
        camera.zoom = camera.zoom * 0.99f;
    }
}

void SubscribeToEvents()
{
    // Subscribe HandleUpdate() function for processing update events
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("ScenePostUpdate", "HandleScenePostUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);
}


void HandleScenePostUpdate(StringHash eventType, VariantMap& eventData)
{
    scene_.physicsWorld2D.DrawDebugGeometry();
}