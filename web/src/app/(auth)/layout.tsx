import { GraduationCap, MessageCircle, Star, BookOpen, Users, Sparkles } from 'lucide-react'

function FloatingIcon({ icon: Icon, className, delay }: { icon: React.ElementType; className: string; delay: string }) {
  return (
    <div
      className={`absolute animate-float ${className}`}
      style={{ animationDelay: delay }}
    >
      <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-3 shadow-lg">
        <Icon className="h-6 w-6 text-blue-600" />
      </div>
    </div>
  )
}

function FeatureCard({ icon: Icon, title, description }: { icon: React.ElementType; title: string; description: string }) {
  return (
    <div className="flex items-start gap-3 p-4 bg-white/50 backdrop-blur-sm rounded-xl">
      <div className="shrink-0 h-10 w-10 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
        <Icon className="h-5 w-5 text-white" />
      </div>
      <div>
        <h3 className="font-semibold text-gray-900">{title}</h3>
        <p className="text-sm text-gray-600">{description}</p>
      </div>
    </div>
  )
}

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen flex">
      {/* Left side - Hero section */}
      <div className="hidden lg:flex lg:w-1/2 xl:w-3/5 bg-gradient-to-br from-blue-600 via-indigo-600 to-purple-700 relative overflow-hidden">
        {/* Animated background shapes */}
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 w-72 h-72 bg-blue-400/30 rounded-full blur-3xl animate-pulse" />
          <div className="absolute bottom-20 right-10 w-96 h-96 bg-purple-400/30 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
          <div className="absolute top-1/2 left-1/3 w-64 h-64 bg-indigo-400/30 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '2s' }} />
        </div>

        {/* Floating icons */}
        <FloatingIcon icon={Star} className="top-[15%] left-[10%]" delay="0s" />
        <FloatingIcon icon={MessageCircle} className="top-[25%] right-[15%]" delay="1s" />
        <FloatingIcon icon={BookOpen} className="bottom-[30%] left-[15%]" delay="2s" />
        <FloatingIcon icon={Users} className="bottom-[20%] right-[20%]" delay="0.5s" />
        <FloatingIcon icon={Sparkles} className="top-[40%] left-[40%]" delay="1.5s" />

        {/* Content */}
        <div className="relative z-10 flex flex-col justify-center px-12 xl:px-20">
          {/* Logo */}
          <div className="flex items-center gap-3 mb-8">
            <div className="h-14 w-14 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
              <GraduationCap className="h-8 w-8 text-white" />
            </div>
            <span className="text-3xl font-bold text-white">Hall Pass</span>
          </div>

          {/* Hero text */}
          <h1 className="text-4xl xl:text-5xl font-bold text-white leading-tight mb-6">
            Connecting Teachers, <br />
            <span className="text-blue-200">Parents & Students</span>
          </h1>

          <p className="text-xl text-blue-100 mb-10 max-w-lg">
            The all-in-one classroom management platform that makes communication easy and celebrates student success.
          </p>

          {/* Feature cards */}
          <div className="space-y-4 max-w-md">
            <FeatureCard
              icon={MessageCircle}
              title="Instant Messaging"
              description="Connect with parents in real-time with secure, private conversations."
            />
            <FeatureCard
              icon={Star}
              title="Behavior Tracking"
              description="Award points and track positive behaviors to motivate students."
            />
            <FeatureCard
              icon={BookOpen}
              title="Class Stories"
              description="Share classroom moments and keep families engaged in learning."
            />
          </div>

          {/* Stats */}
          <div className="flex gap-8 mt-12 pt-8 border-t border-white/20">
            <div>
              <div className="text-3xl font-bold text-white">10k+</div>
              <div className="text-sm text-blue-200">Active Teachers</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white">50k+</div>
              <div className="text-sm text-blue-200">Happy Students</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white">1M+</div>
              <div className="text-sm text-blue-200">Messages Sent</div>
            </div>
          </div>
        </div>
      </div>

      {/* Right side - Auth form */}
      <div className="w-full lg:w-1/2 xl:w-2/5 flex items-center justify-center bg-gradient-to-br from-gray-50 to-blue-50 p-6 lg:p-12">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="lg:hidden flex items-center justify-center gap-3 mb-8">
            <div className="h-12 w-12 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center">
              <GraduationCap className="h-7 w-7 text-white" />
            </div>
            <span className="text-2xl font-bold text-gray-900">Hall Pass</span>
          </div>

          {children}

          {/* Footer */}
          <p className="text-center text-sm text-gray-500 mt-8">
            Trusted by schools nationwide
          </p>
        </div>
      </div>

    </div>
  )
}
