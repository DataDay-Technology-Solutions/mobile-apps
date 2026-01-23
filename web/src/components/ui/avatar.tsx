import { HTMLAttributes, forwardRef } from 'react'
import { cn } from '@/lib/utils'

interface AvatarProps extends HTMLAttributes<HTMLDivElement> {
  src?: string
  alt?: string
  initials?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
}

const Avatar = forwardRef<HTMLDivElement, AvatarProps>(
  ({ className, src, alt, initials, size = 'md', ...props }, ref) => {
    const sizes = {
      sm: 'h-8 w-8 text-xs',
      md: 'h-10 w-10 text-sm',
      lg: 'h-12 w-12 text-base',
      xl: 'h-16 w-16 text-lg',
    }

    const colors = [
      'bg-blue-500',
      'bg-green-500',
      'bg-purple-500',
      'bg-pink-500',
      'bg-orange-500',
      'bg-teal-500',
      'bg-indigo-500',
    ]

    // Generate consistent color from initials
    const colorIndex = initials
      ? initials.charCodeAt(0) % colors.length
      : 0

    return (
      <div
        ref={ref}
        className={cn(
          'relative rounded-full flex items-center justify-center overflow-hidden',
          sizes[size],
          !src && colors[colorIndex],
          className
        )}
        {...props}
      >
        {src ? (
          <img
            src={src}
            alt={alt || initials || 'Avatar'}
            className="h-full w-full object-cover"
          />
        ) : (
          <span className="font-medium text-white">
            {initials || '?'}
          </span>
        )}
      </div>
    )
  }
)
Avatar.displayName = 'Avatar'

export { Avatar }
