//
//  SupabaseConfig.swift
//  HallPass (formerly TeacherLink)
//
//  Supabase configuration for database backend
//

import Foundation
import Supabase

struct SupabaseConfig {
    // Supabase project credentials
    static let supabaseURL = URL(string: "https://hnegcvzcugtcvoqgmgbb.supabase.co")!
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuZWdjdnpjdWd0Y3ZvcWdtZ2JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMjgxNjAsImV4cCI6MjA4NDYwNDE2MH0.Mrr41B52RRWiIOivN2NcOgpd-aP8gicx73saifd3ZQ8"

    // Singleton client
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
}
