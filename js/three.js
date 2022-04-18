import * as THREE from 'three';
import { OrbitControls } from 'OrbitControls';
const loader = new THREE.ObjectLoader();
var camera = new THREE.PerspectiveCamera(25, window.innerWidth / window.innerHeight, 0.01, 1000);
camera.position.set(3.919, 4.297, 9.425);
camera.rotation.set(-54.21 / 180. * Math.PI, 16.78 / 180. * Math.PI, 21.83 / 180. * Math.PI);
const renderer = new THREE.WebGLRenderer();

// TODO: check there is exactly one.
let canvas = document.getElementsByClassName("three_canvas")[0];
let canv_width = canvas.getBoundingClientRect().width;
renderer.setSize(canv_width, canv_width);
const controls = new OrbitControls(camera, renderer.domElement);
controls.update();
export function load_three(name) {
    loader.load(name, function (loaded_scene) {
        loaded_scene.add(camera);
        function animate() {
            // required if controls.enableDamping or controls.autoRotate are set to true
            controls.update();
            renderer.render(loaded_scene, camera);
        }
        renderer.setAnimationLoop(animate);
    });
}
document.addEventListener("DOMContentLoaded", function () {
    canvas.appendChild(renderer.domElement);
});
