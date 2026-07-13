//
//  ViewExtensions.swift
//  colorblindapp
//

import SwiftUI

extension View {
    /// Para textos de botón: evita que el contenido se corte o salte a dos
    /// líneas en pantallas estrechas — se mantiene en una línea y se escala
    /// hasta el 75% si hace falta.
    func singleLineFitted() -> some View {
        lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}
