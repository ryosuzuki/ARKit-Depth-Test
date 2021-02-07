//
//  Extensions.swift
//  Depth-Test
//
//  Created by Ryo Suzuki on 2/6/21.
//

import ARKit
import RealityKit

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
