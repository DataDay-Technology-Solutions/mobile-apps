'use client'

import Link from 'next/link'
import { useState } from 'react'

export default function LandingPage() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      {/* Navigation */}
      <nav className="bg-white/80 backdrop-blur-md sticky top-0 z-50 border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center">
                <span className="text-white font-bold text-xl">H</span>
              </div>
              <span className="font-bold text-xl text-gray-900">HallPass</span>
            </div>

            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-gray-600 hover:text-gray-900 transition">Features</a>
              <a href="#how-it-works" className="text-gray-600 hover:text-gray-900 transition">How It Works</a>
              <a href="#testimonials" className="text-gray-600 hover:text-gray-900 transition">Testimonials</a>
              <Link href="/login" className="text-gray-600 hover:text-gray-900 transition">Sign In</Link>
              <Link
                href="/signup"
                className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition font-medium"
              >
                Get Started Free
              </Link>
            </div>

            <button
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-white border-t">
            <div className="px-4 py-4 space-y-4">
              <a href="#features" className="block text-gray-600">Features</a>
              <a href="#how-it-works" className="block text-gray-600">How It Works</a>
              <Link href="/login" className="block text-gray-600">Sign In</Link>
              <Link href="/signup" className="block bg-blue-600 text-white px-4 py-2 rounded-lg text-center">
                Get Started Free
              </Link>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="pt-20 pb-32 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 bg-blue-100 text-blue-700 px-4 py-2 rounded-full text-sm font-medium mb-8">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
            </span>
            Trusted by 500+ schools nationwide
          </div>

          <h1 className="text-5xl md:text-7xl font-bold text-gray-900 mb-6 leading-tight">
            Connect Classrooms.<br />
            <span className="text-blue-600">Engage Families.</span>
          </h1>

          <p className="text-xl text-gray-600 mb-10 max-w-2xl mx-auto">
            The all-in-one platform that brings teachers, parents, and students together.
            Share moments, track progress, and build stronger school communities.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/signup"
              className="bg-blue-600 text-white px-8 py-4 rounded-xl text-lg font-semibold hover:bg-blue-700 transition shadow-lg shadow-blue-500/30"
            >
              Start Free Trial
            </Link>
            <a
              href="#features"
              className="bg-white text-gray-700 px-8 py-4 rounded-xl text-lg font-semibold hover:bg-gray-50 transition border border-gray-200"
            >
              See Features
            </a>
          </div>

          {/* Hero Image/Preview */}
          <div className="mt-16 relative">
            <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-1 shadow-2xl max-w-4xl mx-auto">
              <div className="bg-gray-900 rounded-xl p-4">
                <div className="flex gap-2 mb-4">
                  <div className="w-3 h-3 rounded-full bg-red-500"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                  <div className="w-3 h-3 rounded-full bg-green-500"></div>
                </div>
                <div className="bg-white rounded-lg p-6 text-left">
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">
                      MS
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900">Mrs. Smith&apos;s 3rd Grade</p>
                      <p className="text-sm text-gray-500">Just now</p>
                    </div>
                  </div>
                  <p className="text-gray-700 mb-4">🎨 Amazing art projects today! The kids worked so hard on their self-portraits. So proud of everyone!</p>
                  <div className="flex gap-2">
                    <div className="w-24 h-24 bg-gradient-to-br from-pink-200 to-purple-200 rounded-lg"></div>
                    <div className="w-24 h-24 bg-gradient-to-br from-blue-200 to-green-200 rounded-lg"></div>
                    <div className="w-24 h-24 bg-gradient-to-br from-yellow-200 to-orange-200 rounded-lg"></div>
                  </div>
                  <div className="flex items-center gap-4 mt-4 text-gray-500">
                    <span className="flex items-center gap-1">❤️ 24 likes</span>
                    <span className="flex items-center gap-1">💬 8 comments</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Everything You Need</h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Powerful features designed to make classroom communication effortless
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Feature 1 - Photo Sharing */}
            <div className="bg-gradient-to-br from-pink-50 to-purple-50 rounded-2xl p-8 border border-pink-100">
              <div className="w-14 h-14 bg-gradient-to-br from-pink-500 to-purple-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Photo & Story Sharing</h3>
              <p className="text-gray-600">
                Share classroom moments instantly with photos, updates, and announcements.
                Parents never miss a special moment.
              </p>
            </div>

            {/* Feature 2 - Behavior Points */}
            <div className="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-2xl p-8 border border-yellow-100">
              <div className="w-14 h-14 bg-gradient-to-br from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Behavior Points System</h3>
              <p className="text-gray-600">
                Track and reward positive behavior with our ClassDojo-style points system.
                Motivate students and keep parents informed.
              </p>
            </div>

            {/* Feature 3 - Direct Messaging */}
            <div className="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-2xl p-8 border border-blue-100">
              <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Secure Messaging</h3>
              <p className="text-gray-600">
                Private, direct communication between teachers and parents.
                Keep conversations organized and professional.
              </p>
            </div>

            {/* Feature 4 - Class Management */}
            <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-2xl p-8 border border-green-100">
              <div className="w-14 h-14 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Easy Class Management</h3>
              <p className="text-gray-600">
                Add students, manage rosters, and invite parents with simple class codes.
                Set up takes just minutes.
              </p>
            </div>

            {/* Feature 5 - Admin Dashboard */}
            <div className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-2xl p-8 border border-purple-100">
              <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-indigo-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Admin Dashboards</h3>
              <p className="text-gray-600">
                Powerful dashboards for principals and district admins.
                View reports, manage schools, and export data with ease.
              </p>
            </div>

            {/* Feature 6 - Mobile Apps */}
            <div className="bg-gradient-to-br from-rose-50 to-pink-50 rounded-2xl p-8 border border-rose-100">
              <div className="w-14 h-14 bg-gradient-to-br from-rose-500 to-pink-500 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Native Mobile Apps</h3>
              <p className="text-gray-600">
                Beautiful iOS and Android apps for teachers and parents.
                Stay connected on the go with push notifications.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="py-24 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Get Started in Minutes</h2>
            <p className="text-xl text-gray-600">Three simple steps to transform your classroom communication</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                1
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Create Your Class</h3>
              <p className="text-gray-600">
                Sign up as a teacher and create your classroom in seconds.
                Add your students and customize your settings.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-blue-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                2
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Invite Parents</h3>
              <p className="text-gray-600">
                Share your unique class code with parents.
                They can join with the code and link to their child instantly.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-blue-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                3
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">Start Sharing</h3>
              <p className="text-gray-600">
                Post photos, award points, send messages, and keep
                parents engaged with their child&apos;s education.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Mobile App Coming Soon */}
      <section className="py-24 bg-gradient-to-b from-gray-900 via-blue-950 to-gray-900 relative overflow-hidden">
        {/* Background effects */}
        <div className="absolute inset-0">
          <div className="absolute top-1/3 left-1/4 w-64 h-64 bg-blue-500/20 rounded-full blur-3xl"></div>
          <div className="absolute bottom-1/4 right-1/3 w-64 h-64 bg-purple-500/20 rounded-full blur-3xl"></div>
        </div>

        <div className="relative z-10 max-w-7xl mx-auto px-4">
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/20 border border-blue-500/30 rounded-full mb-6">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-400"></span>
              </span>
              <span className="text-blue-300 font-semibold text-sm">Coming Soon to App Store</span>
            </div>
            <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
              HallPass <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400">Mobile</span>
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              The full HallPass experience in your pocket. Native iOS app for teachers and parents
              with push notifications, offline access, and everything you love about HallPass.
            </p>
          </div>

          <div className="flex flex-col lg:flex-row items-center justify-center gap-8 lg:gap-16">
            {/* Phone Mockup - Teacher View */}
            <div className="relative group">
              <div className="absolute -inset-4 bg-gradient-to-r from-blue-500/30 to-purple-500/30 rounded-[3rem] blur-2xl opacity-50 group-hover:opacity-70 transition-opacity"></div>
              <div className="relative w-[280px] bg-gray-800 rounded-[2.5rem] p-3 border-4 border-gray-700 shadow-2xl">
                {/* Phone notch */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-gray-700 rounded-b-2xl"></div>
                {/* Screen */}
                <div className="bg-gray-50 rounded-[2rem] overflow-hidden h-[500px]">
                  <div className="h-8 bg-white flex items-center justify-center text-xs text-gray-400">
                    9:41
                  </div>
                  <div className="p-4">
                    <div className="flex justify-between items-center mb-6">
                      <div>
                        <p className="text-xs text-gray-500">Good morning,</p>
                        <p className="text-lg font-bold text-gray-900">Mrs. Smith</p>
                      </div>
                      <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-500 rounded-full"></div>
                    </div>
                    <div className="grid grid-cols-2 gap-3 mb-6">
                      <div className="bg-white rounded-xl p-3 shadow-sm">
                        <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center mb-2">
                          <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                          </svg>
                        </div>
                        <p className="text-xl font-bold text-gray-900">24</p>
                        <p className="text-xs text-gray-500">Students</p>
                      </div>
                      <div className="bg-white rounded-xl p-3 shadow-sm">
                        <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center mb-2">
                          <svg className="w-4 h-4 text-yellow-600" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                          </svg>
                        </div>
                        <p className="text-xl font-bold text-gray-900">847</p>
                        <p className="text-xs text-gray-500">Points Today</p>
                      </div>
                    </div>
                    <p className="text-sm font-semibold text-gray-900 mb-3">Recent Posts</p>
                    <div className="bg-white rounded-xl p-3 shadow-sm">
                      <div className="flex items-center gap-2 mb-2">
                        <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-xs font-bold">MS</div>
                        <div>
                          <p className="text-sm font-medium text-gray-900">Art class today!</p>
                          <p className="text-xs text-gray-500">2 min ago</p>
                        </div>
                      </div>
                      <div className="flex gap-1">
                        <div className="w-12 h-12 bg-gradient-to-br from-pink-200 to-purple-200 rounded-lg"></div>
                        <div className="w-12 h-12 bg-gradient-to-br from-blue-200 to-green-200 rounded-lg"></div>
                        <div className="w-12 h-12 bg-gradient-to-br from-yellow-200 to-orange-200 rounded-lg"></div>
                      </div>
                    </div>
                  </div>
                  <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-100 flex justify-around py-3 rounded-b-[2rem]">
                    <div className="flex flex-col items-center text-blue-600">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
                      </svg>
                      <span className="text-[10px] mt-1">Home</span>
                    </div>
                    <div className="flex flex-col items-center text-gray-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                      <span className="text-[10px] mt-1">Students</span>
                    </div>
                    <div className="flex flex-col items-center text-gray-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                      </svg>
                      <span className="text-[10px] mt-1">Messages</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Phone Mockup - Parent View */}
            <div className="relative group hidden lg:block">
              <div className="absolute -inset-4 bg-gradient-to-r from-purple-500/30 to-pink-500/30 rounded-[3rem] blur-2xl opacity-50 group-hover:opacity-70 transition-opacity"></div>
              <div className="relative w-[280px] bg-gray-800 rounded-[2.5rem] p-3 border-4 border-gray-700 shadow-2xl">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-gray-700 rounded-b-2xl"></div>
                <div className="bg-gray-50 rounded-[2rem] overflow-hidden h-[500px]">
                  <div className="h-8 bg-white flex items-center justify-center text-xs text-gray-400">
                    9:41
                  </div>
                  <div className="p-4">
                    <div className="flex items-center gap-2 mb-4">
                      <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                      </svg>
                      <span className="text-sm text-blue-600 font-medium">Back</span>
                    </div>
                    <div className="text-center mb-4">
                      <div className="w-16 h-16 bg-gradient-to-br from-green-400 to-blue-500 rounded-full mx-auto mb-3 flex items-center justify-center text-white font-bold text-xl">EJ</div>
                      <h3 className="text-lg font-bold text-gray-900">Emma Johnson</h3>
                      <p className="text-sm text-gray-500">Mrs. Smith&apos;s Class</p>
                    </div>
                    <div className="bg-yellow-50 rounded-xl p-3 mb-4 text-center border border-yellow-200">
                      <div className="flex items-center justify-center gap-1 mb-1">
                        <svg className="w-5 h-5 text-yellow-500" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                        </svg>
                        <p className="text-2xl font-bold text-yellow-600">156</p>
                      </div>
                      <p className="text-xs text-yellow-600">Total Points</p>
                    </div>
                    <p className="text-sm font-semibold text-gray-900 mb-2">Recent Activity</p>
                    <div className="space-y-2">
                      <div className="bg-white rounded-lg p-2 shadow-sm flex items-center gap-2">
                        <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                          <span className="text-green-600 text-xs font-bold">+5</span>
                        </div>
                        <div className="flex-1">
                          <p className="text-xs font-medium text-gray-900">Helping others</p>
                          <p className="text-[10px] text-gray-500">Today, 2:30 PM</p>
                        </div>
                      </div>
                      <div className="bg-white rounded-lg p-2 shadow-sm flex items-center gap-2">
                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-blue-600 text-xs font-bold">+3</span>
                        </div>
                        <div className="flex-1">
                          <p className="text-xs font-medium text-gray-900">Great participation</p>
                          <p className="text-[10px] text-gray-500">Today, 11:15 AM</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Feature list */}
          <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto">
            <div className="text-center">
              <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
              </div>
              <p className="text-white font-semibold">Push Notifications</p>
              <p className="text-sm text-gray-400 mt-1">Never miss a moment</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-purple-500/20 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <p className="text-white font-semibold">Photo Sharing</p>
              <p className="text-sm text-gray-400 mt-1">Share classroom moments</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-yellow-500/20 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-yellow-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                </svg>
              </div>
              <p className="text-white font-semibold">Behavior Points</p>
              <p className="text-sm text-gray-400 mt-1">Track & reward students</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <p className="text-white font-semibold">Direct Messages</p>
              <p className="text-sm text-gray-400 mt-1">Private teacher-parent chat</p>
            </div>
          </div>

          {/* App Store Badge */}
          <div className="mt-12 text-center">
            <p className="text-gray-400 mb-4">Native SwiftUI app for iOS. Android coming later.</p>
            <div className="inline-flex items-center gap-3 px-6 py-3 bg-gray-800/50 border border-gray-700 rounded-xl">
              <svg className="w-8 h-8 text-white" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <div className="text-left">
                <p className="text-xs text-gray-400">Waiting for</p>
                <p className="text-white font-semibold">App Store Review</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Loved by Educators</h2>
            <p className="text-xl text-gray-600">See what teachers and parents are saying</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-gray-50 rounded-2xl p-8">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map(i => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                ))}
              </div>
              <p className="text-gray-600 mb-6">
                &quot;HallPass has transformed how I communicate with parents. They love seeing photos of their kids learning!&quot;
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">
                  SJ
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Sarah Johnson</p>
                  <p className="text-sm text-gray-500">2nd Grade Teacher</p>
                </div>
              </div>
            </div>

            <div className="bg-gray-50 rounded-2xl p-8">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map(i => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                ))}
              </div>
              <p className="text-gray-600 mb-6">
                &quot;As a busy parent, I finally feel connected to what&apos;s happening in my daughter&apos;s classroom. The points system motivates her too!&quot;
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center text-white font-bold">
                  MR
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Michael Rodriguez</p>
                  <p className="text-sm text-gray-500">Parent</p>
                </div>
              </div>
            </div>

            <div className="bg-gray-50 rounded-2xl p-8">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map(i => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                ))}
              </div>
              <p className="text-gray-600 mb-6">
                &quot;The admin dashboard gives me visibility across all our schools. Reports and data export make my job so much easier.&quot;
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center text-white font-bold">
                  DW
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Dr. Williams</p>
                  <p className="text-sm text-gray-500">District Administrator</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 bg-gradient-to-r from-blue-600 to-purple-600">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-4xl font-bold text-white mb-6">
            Ready to Transform Your Classroom?
          </h2>
          <p className="text-xl text-blue-100 mb-10">
            Join thousands of teachers who are building stronger connections with families.
            Start your free trial today - no credit card required.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/signup"
              className="bg-white text-blue-600 px-8 py-4 rounded-xl text-lg font-semibold hover:bg-gray-100 transition"
            >
              Get Started Free
            </Link>
            <Link
              href="/login"
              className="bg-transparent text-white px-8 py-4 rounded-xl text-lg font-semibold hover:bg-white/10 transition border-2 border-white"
            >
              Sign In
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-400 py-12">
        <div className="max-w-7xl mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold">H</span>
                </div>
                <span className="font-bold text-white">HallPass</span>
              </div>
              <p className="text-sm">
                Connecting classrooms and families through better communication.
              </p>
            </div>

            <div>
              <h4 className="font-semibold text-white mb-4">Product</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#features" className="hover:text-white transition">Features</a></li>
                <li><a href="#" className="hover:text-white transition">Pricing</a></li>
                <li><a href="#" className="hover:text-white transition">Mobile Apps</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-white mb-4">Company</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white transition">About</a></li>
                <li><a href="#" className="hover:text-white transition">Contact</a></li>
                <li><a href="#" className="hover:text-white transition">Careers</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-white mb-4">Legal</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white transition">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-white transition">Terms of Service</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-gray-800 mt-12 pt-8 text-center text-sm">
            <p>&copy; {new Date().getFullYear()} HallPass. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
