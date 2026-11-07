import React, { useRef, useState, useEffect } from 'react';
import * as THREE from 'three';
import { GLTFExporter } from 'three/examples/jsm/exporters/GLTFExporter';

export default function RobotModel() {
  const mountRef = useRef(null);
  const sceneRef = useRef(null);
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    // Scene setup
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1a1a);
    sceneRef.current = scene;

    const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.set(1.2, 0.8, 1.2);
    camera.lookAt(0, 0.2, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    mountRef.current.appendChild(renderer.domElement);

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const mainLight = new THREE.DirectionalLight(0xffffff, 0.8);
    mainLight.position.set(5, 10, 5);
    mainLight.castShadow = true;
    mainLight.shadow.mapSize.width = 2048;
    mainLight.shadow.mapSize.height = 2048;
    scene.add(mainLight);

    const fillLight = new THREE.DirectionalLight(0xffffff, 0.3);
    fillLight.position.set(-5, 5, -5);
    scene.add(fillLight);

    // Ground plane
    const groundGeometry = new THREE.PlaneGeometry(10, 10);
    const groundMaterial = new THREE.MeshStandardMaterial({ color: 0x333333 });
    const ground = new THREE.Mesh(groundGeometry, groundMaterial);
    ground.rotation.x = -Math.PI / 2;
    ground.receiveShadow = true;
    scene.add(ground);

    // Materials
    const whitePlasticMat = new THREE.MeshStandardMaterial({
      color: 0xf5f5f5,
      roughness: 0.3,
      metalness: 0.1
    });

    const blackPlasticMat = new THREE.MeshStandardMaterial({
      color: 0x1a1a1a,
      roughness: 0.4,
      metalness: 0.1
    });

    const yellowStripeMat = new THREE.MeshStandardMaterial({
      color: 0xffa500,
      roughness: 0.5,
      metalness: 0.0
    });

    const grayPanelMat = new THREE.MeshStandardMaterial({
      color: 0x404040,
      roughness: 0.6,
      metalness: 0.2
    });

    const metalMat = new THREE.MeshStandardMaterial({
      color: 0x888888,
      roughness: 0.3,
      metalness: 0.8
    });

    const rubberMat = new THREE.MeshStandardMaterial({
      color: 0x0a0a0a,
      roughness: 0.9,
      metalness: 0.0
    });

    // Robot group
    const robot = new THREE.Group();
    scene.add(robot);

    // CHASSIS BASE (wood platform - 60cm x 35cm)
    const chassisBase = new THREE.Mesh(
      new THREE.BoxGeometry(0.6, 0.02, 0.35),
      new THREE.MeshStandardMaterial({ color: 0x8b6f47, roughness: 0.8 })
    );
    chassisBase.position.y = 0.12;
    chassisBase.castShadow = true;
    robot.add(chassisBase);

    // MAIN BODY SHELL - rounded white enclosure
    const bodyGroup = new THREE.Group();
    bodyGroup.position.y = 0.13;
    robot.add(bodyGroup);

    // Main body dome (elongated rounded shape)
    const bodyGeometry = new THREE.CapsuleGeometry(0.15, 0.4, 16, 32);
    bodyGeometry.rotateZ(Math.PI / 2);
    const bodyShell = new THREE.Mesh(bodyGeometry, whitePlasticMat);
    bodyShell.castShadow = true;
    bodyGroup.add(bodyShell);

    // Front and rear rounded caps
    const frontCap = new THREE.Mesh(
      new THREE.SphereGeometry(0.15, 16, 16, 0, Math.PI),
      whitePlasticMat
    );
    frontCap.position.set(0.2, 0, 0);
    frontCap.rotation.y = Math.PI / 2;
    frontCap.castShadow = true;
    bodyGroup.add(frontCap);

    const rearCap = new THREE.Mesh(
      new THREE.SphereGeometry(0.15, 16, 16, 0, Math.PI),
      whitePlasticMat
    );
    rearCap.position.set(-0.2, 0, 0);
    rearCap.rotation.y = -Math.PI / 2;
    rearCap.castShadow = true;
    bodyGroup.add(rearCap);

    // Top black panel (triangular vent)
    const panelShape = new THREE.Shape();
    panelShape.moveTo(-0.08, 0.12);
    panelShape.lineTo(0.08, 0.12);
    panelShape.lineTo(0, 0.25);
    panelShape.closePath();

    const panelGeometry = new THREE.ExtrudeGeometry(panelShape, {
      depth: 0.02,
      bevelEnabled: false
    });
    const topPanel = new THREE.Mesh(panelGeometry, grayPanelMat);
    topPanel.rotation.x = Math.PI / 2;
    topPanel.position.set(-0.05, 0.16, -0.01);
    topPanel.castShadow = true;
    bodyGroup.add(topPanel);

    // Hazard stripe band around middle
    const stripePositions = [
      { x: 0.15, width: 0.08, angle: 20 },
      { x: 0.05, width: 0.08, angle: 20 },
      { x: -0.05, width: 0.08, angle: 20 },
      { x: -0.15, width: 0.08, angle: 20 }
    ];

    stripePositions.forEach((pos, i) => {
      // Yellow stripe
      const yellowStripe = new THREE.Mesh(
        new THREE.BoxGeometry(pos.width, 0.05, 0.32),
        yellowStripeMat
      );
      yellowStripe.position.set(pos.x, 0, 0);
      yellowStripe.rotation.y = (pos.angle * Math.PI) / 180;
      bodyGroup.add(yellowStripe);

      // Black stripe
      if (i < stripePositions.length - 1) {
        const blackStripe = new THREE.Mesh(
          new THREE.BoxGeometry(pos.width * 0.6, 0.051, 0.32),
          blackPlasticMat
        );
        blackStripe.position.set(pos.x - 0.04, 0, 0);
        blackStripe.rotation.y = (pos.angle * Math.PI) / 180;
        bodyGroup.add(blackStripe);
      }
    });

    // Ventilation holes on front
    for (let i = 0; i < 15; i++) {
      const hole = new THREE.Mesh(
        new THREE.CylinderGeometry(0.004, 0.004, 0.02, 8),
        blackPlasticMat
      );
      hole.rotation.z = Math.PI / 2;
      hole.position.set(0.22, 0.1, -0.12 + i * 0.016);
      bodyGroup.add(hole);
    }

    // WHEELS (4 wheels, positioned correctly)
    const wheelPositions = [
      { x: 0.165, z: 0.175 },  // Front right
      { x: 0.165, z: -0.175 }, // Front left
      { x: -0.165, z: 0.175 }, // Rear right
      { x: -0.165, z: -0.175 } // Rear left
    ];

    wheelPositions.forEach(pos => {
      const wheelGroup = new THREE.Group();
      wheelGroup.position.set(pos.x, 0.08, pos.z);

      // Tire (black rubber with tread)
      const tire = new THREE.Mesh(
        new THREE.CylinderGeometry(0.08, 0.08, 0.06, 32),
        rubberMat
      );
      tire.rotation.z = Math.PI / 2;
      tire.castShadow = true;
      wheelGroup.add(tire);

      // Tread pattern
      for (let i = 0; i < 12; i++) {
        const tread = new THREE.Mesh(
          new THREE.BoxGeometry(0.08, 0.003, 0.015),
          new THREE.MeshStandardMaterial({ color: 0x050505 })
        );
        tread.position.set(0, Math.cos(i * Math.PI / 6) * 0.08, Math.sin(i * Math.PI / 6) * 0.08);
        tread.rotation.x = i * Math.PI / 6;
        wheelGroup.add(tread);
      }

      // White center cap with reflective surface
      const hubCap = new THREE.Mesh(
        new THREE.CylinderGeometry(0.035, 0.035, 0.005, 32),
        new THREE.MeshStandardMaterial({ 
          color: 0xeeeeee, 
          roughness: 0.1, 
          metalness: 0.3 
        })
      );
      hubCap.rotation.z = Math.PI / 2;
      hubCap.position.x = 0.031;
      wheelGroup.add(hubCap);

      robot.add(wheelGroup);
    });

    // ROBOTIC ARM (6-DOF, mounted at front)
    const armGroup = new THREE.Group();
    armGroup.position.set(0.25, 0.13, 0);
    robot.add(armGroup);

    // Base servo mount
    const baseMount = new THREE.Mesh(
      new THREE.BoxGeometry(0.06, 0.04, 0.08),
      blackPlasticMat
    );
    baseMount.castShadow = true;
    armGroup.add(baseMount);

    // Servo 1 (base rotation)
    const servo1 = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.035, 0.04),
      blackPlasticMat
    );
    servo1.position.y = 0.04;
    servo1.castShadow = true;
    armGroup.add(servo1);

    // Link 1
    const link1 = new THREE.Mesh(
      new THREE.BoxGeometry(0.025, 0.12, 0.02),
      blackPlasticMat
    );
    link1.position.set(0, 0.1, 0);
    link1.castShadow = true;
    armGroup.add(link1);

    // Servo 2
    const servo2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.035, 0.04),
      blackPlasticMat
    );
    servo2.position.set(0, 0.16, 0);
    servo2.castShadow = true;
    armGroup.add(servo2);

    // Link 2 (upper arm)
    const link2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.02, 0.1, 0.025),
      blackPlasticMat
    );
    link2.position.set(0, 0.25, 0);
    link2.rotation.z = -0.3;
    link2.castShadow = true;
    armGroup.add(link2);

    // Servo 3
    const servo3 = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.03, 0.035),
      blackPlasticMat
    );
    servo3.position.set(-0.02, 0.32, 0);
    servo3.castShadow = true;
    armGroup.add(servo3);

    // Wrist assembly
    const wrist = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.06, 0.03),
      blackPlasticMat
    );
    wrist.position.set(-0.04, 0.38, 0);
    wrist.castShadow = true;
    armGroup.add(wrist);

    // Gripper base
    const gripperBase = new THREE.Mesh(
      new THREE.BoxGeometry(0.03, 0.04, 0.035),
      blackPlasticMat
    );
    gripperBase.position.set(-0.04, 0.43, 0);
    gripperBase.castShadow = true;
    armGroup.add(gripperBase);

    // Gripper fingers
    const finger1 = new THREE.Mesh(
      new THREE.BoxGeometry(0.01, 0.05, 0.015),
      blackPlasticMat
    );
    finger1.position.set(-0.03, 0.48, 0.015);
    finger1.castShadow = true;
    armGroup.add(finger1);

    const finger2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.01, 0.05, 0.015),
      blackPlasticMat
    );
    finger2.position.set(-0.03, 0.48, -0.015);
    finger2.castShadow = true;
    armGroup.add(finger2);

    // Orange wiring
    for (let i = 0; i < 5; i++) {
      const wire = new THREE.Mesh(
        new THREE.CylinderGeometry(0.002, 0.002, 0.15, 8),
        new THREE.MeshStandardMaterial({ color: 0xff6600 })
      );
      wire.position.set(-0.01, 0.2 + i * 0.03, 0.02 + i * 0.003);
      wire.rotation.z = 0.2 + i * 0.1;
      armGroup.add(wire);
    }

    // Camera/sensor on top of arm
    const camera_sensor = new THREE.Mesh(
      new THREE.BoxGeometry(0.025, 0.025, 0.015),
      blackPlasticMat
    );
    camera_sensor.position.set(-0.04, 0.52, 0);
    camera_sensor.castShadow = true;
    armGroup.add(camera_sensor);

    // Camera lens
    const lens = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.008, 0.005, 16),
      new THREE.MeshStandardMaterial({ color: 0x1a1aff, emissive: 0x0000ff, emissiveIntensity: 0.3 })
    );
    lens.rotation.x = Math.PI / 2;
    lens.position.set(-0.04, 0.525, 0.01);
    armGroup.add(lens);

    // Animation
    let time = 0;
    const animate = () => {
      requestAnimationFrame(animate);
      time += 0.01;
      
      robot.rotation.y = Math.sin(time * 0.3) * 0.3;
      
      renderer.render(scene, camera);
    };
    animate();

    // Handle resize
    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };
    window.addEventListener('resize', handleResize);

    // Cleanup
    return () => {
      window.removeEventListener('resize', handleResize);
      mountRef.current?.removeChild(renderer.domElement);
    };
  }, []);

  const exportGLB = () => {
    if (!sceneRef.current) return;
    
    setExporting(true);
    
    const exporter = new GLTFExporter();
    
    // Find the robot group in the scene
    const robot = sceneRef.current.children.find(child => child.type === 'Group');
    
    if (!robot) {
      alert('Robot model not found in scene');
      setExporting(false);
      return;
    }

    exporter.parse(
      robot,
      (gltf) => {
        const blob = new Blob([gltf], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'robot-model.glb';
        link.click();
        URL.revokeObjectURL(url);
        setExporting(false);
      },
      (error) => {
        console.error('Export error:', error);
        alert('Export failed: ' + error.message);
        setExporting(false);
      },
      { binary: true }
    );
  };

  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative', margin: 0, padding: 0 }}>
      <div ref={mountRef} style={{ width: '100%', height: '100%' }} />
      <button
        onClick={exportGLB}
        disabled={exporting}
        style={{
          position: 'absolute',
          top: '20px',
          right: '20px',
          padding: '15px 30px',
          fontSize: '16px',
          fontWeight: 'bold',
          backgroundColor: exporting ? '#666' : '#ff6600',
          color: 'white',
          border: 'none',
          borderRadius: '8px',
          cursor: exporting ? 'not-allowed' : 'pointer',
          boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
          zIndex: 1000
        }}
      >
        {exporting ? 'EXPORTING...' : 'DOWNLOAD GLB FOR QUEST 3'}
      </button>
      <div style={{
        position: 'absolute',
        bottom: '20px',
        left: '20px',
        color: 'white',
        fontFamily: 'monospace',
        fontSize: '14px',
        backgroundColor: 'rgba(0,0,0,0.7)',
        padding: '10px',
        borderRadius: '5px'
      }}>
        <div>Length: 60cm | Wheelbase: 33cm | Track: 35cm</div>
        <div>6-DOF Robotic Arm | 4 Wheels | Camera Sensor</div>
      </div>
    </div>
  );
}
