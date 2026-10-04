import 'dart:math' as math;

const _rad = math.pi / 180;
const degPerRad = 180 / math.pi;

/// Back-camera direction from W3C DeviceOrientation angles.
///
/// The spec defines the device→earth rotation as R = Rz(α)·Rx(β)·Ry(γ)
/// (intrinsic Z-X'-Y''), earth frame x = East, y = North, z = Up; device frame
/// x = right edge, y = top edge, z = out of the screen. α grows
/// counter-clockwise seen from above, so a compass heading is 360 − α.
///
/// The back camera looks along device −z, so its world direction is
/// w = R·(0,0,−1) = −(third column of R):
///   w.x = −cosα·sinγ − sinα·sinβ·cosγ
///   w.y = −sinα·sinγ + cosα·sinβ·cosγ
///   w.z = −cosβ·cosγ
/// Checks: flat face-up (β=γ=0) → w = (0,0,−1), straight down; upright
/// portrait facing north (α=0, β=90°) → w = (0,1,0), north.
/// Azimuth = atan2(w.x, w.y) (clockwise from north), elevation = asin(w.z).
({double x, double y, double z}) cameraAxis(double alpha, double beta, double gamma) {
  final ca = math.cos(alpha * _rad), sa = math.sin(alpha * _rad);
  final cb = math.cos(beta * _rad), sb = math.sin(beta * _rad);
  final cg = math.cos(gamma * _rad), sg = math.sin(gamma * _rad);
  return (x: -ca * sg - sa * sb * cg, y: -sa * sg + ca * sb * cg, z: -cb * cg);
}
