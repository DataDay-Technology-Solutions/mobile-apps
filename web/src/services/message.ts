import { createClient } from '@/lib/supabase/client'
import type { Conversation, Message } from '@/types'

export class MessageError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'MessageError'
  }
}

export const messageService = {
  // Conversation operations

  async createConversation(
    participantIds: string[],
    participantNames: Record<string, string>,
    classId?: string,
    studentId?: string,
    studentName?: string
  ): Promise<Conversation> {
    const supabase = createClient()

    // Sort participant IDs for consistent lookup
    const sortedIds = [...participantIds].sort()

    const newConversation = {
      participant_ids: sortedIds,
      participant_names: participantNames,
      class_id: classId,
      student_id: studentId,
      student_name: studentName,
      unread_counts: Object.fromEntries(sortedIds.map(id => [id, 0])),
      created_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('conversations')
      .insert(newConversation)
      .select()
      .single()

    if (error) throw new MessageError(error.message)
    return data as Conversation
  },

  async getOrCreateConversation(
    participantIds: string[],
    participantNames: Record<string, string>,
    classId?: string,
    studentId?: string,
    studentName?: string
  ): Promise<Conversation> {
    const supabase = createClient()
    const sortedIds = [...participantIds].sort()

    // Try to find existing conversation
    const { data: existing } = await supabase
      .from('conversations')
      .select()
      .contains('participant_ids', sortedIds)
      .single()

    if (existing) {
      return existing as Conversation
    }

    // Create new conversation
    return this.createConversation(participantIds, participantNames, classId, studentId, studentName)
  },

  async getConversation(id: string): Promise<Conversation | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('conversations')
      .select()
      .eq('id', id)
      .single()

    if (error) return null
    return data as Conversation
  },

  async getConversationsForUser(userId: string): Promise<Conversation[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('conversations')
      .select()
      .contains('participant_ids', [userId])
      .order('last_message_date', { ascending: false, nullsFirst: false })

    if (error) throw new MessageError(error.message)
    return data as Conversation[]
  },

  async getTotalUnreadCount(userId: string): Promise<number> {
    const conversations = await this.getConversationsForUser(userId)
    return conversations.reduce((total, conv) => {
      return total + (conv.unread_counts[userId] || 0)
    }, 0)
  },

  // Message operations

  async sendMessage(
    conversationId: string,
    senderId: string,
    senderName: string,
    content: string
  ): Promise<Message> {
    const supabase = createClient()

    const newMessage = {
      conversation_id: conversationId,
      sender_id: senderId,
      sender_name: senderName,
      content,
      is_read: false,
      created_at: new Date().toISOString(),
    }

    const { data: messageData, error: messageError } = await supabase
      .from('messages')
      .insert(newMessage)
      .select()
      .single()

    if (messageError) throw new MessageError(messageError.message)

    // Update conversation with last message info
    const conversation = await this.getConversation(conversationId)
    if (conversation) {
      // Increment unread count for all participants except sender
      const updatedUnreadCounts = { ...conversation.unread_counts }
      for (const participantId of conversation.participant_ids) {
        if (participantId !== senderId) {
          updatedUnreadCounts[participantId] = (updatedUnreadCounts[participantId] || 0) + 1
        }
      }

      await supabase
        .from('conversations')
        .update({
          last_message: content,
          last_message_date: newMessage.created_at,
          last_message_sender_id: senderId,
          unread_counts: updatedUnreadCounts,
        })
        .eq('id', conversationId)
    }

    return messageData as Message
  },

  async getMessages(conversationId: string, limit: number = 50): Promise<Message[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('messages')
      .select()
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(limit)

    if (error) throw new MessageError(error.message)
    return data as Message[]
  },

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    const supabase = createClient()

    // Reset unread count for this user
    const conversation = await this.getConversation(conversationId)
    if (conversation) {
      const updatedUnreadCounts = { ...conversation.unread_counts, [userId]: 0 }
      await supabase
        .from('conversations')
        .update({ unread_counts: updatedUnreadCounts })
        .eq('id', conversationId)
    }

    // Mark all messages as read
    await supabase
      .from('messages')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('conversation_id', conversationId)
      .neq('sender_id', userId)
      .eq('is_read', false)
  },

  async deleteMessage(id: string): Promise<void> {
    const supabase = createClient()

    const { error } = await supabase
      .from('messages')
      .delete()
      .eq('id', id)

    if (error) throw new MessageError(error.message)
  },

  // Broadcast message (teacher to all parents in class)
  async sendBroadcastMessage(
    teacherId: string,
    teacherName: string,
    classId: string,
    content: string,
    parentIds: string[]
  ): Promise<void> {
    for (const parentId of parentIds) {
      // Get or create conversation with each parent
      const { data: parentData } = await createClient()
        .from('users')
        .select('name')
        .eq('id', parentId)
        .single()

      const participantNames = {
        [teacherId]: teacherName,
        [parentId]: parentData?.name || 'Parent',
      }

      const conversation = await this.getOrCreateConversation(
        [teacherId, parentId],
        participantNames,
        classId
      )

      await this.sendMessage(conversation.id, teacherId, teacherName, content)
    }
  },

  // Real-time subscriptions

  subscribeToConversations(userId: string, callback: (conversations: Conversation[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`conversations_${userId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'conversations' },
        async () => {
          // Refetch conversations on any change
          const conversations = await this.getConversationsForUser(userId)
          callback(conversations)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },

  subscribeToMessages(conversationId: string, callback: (messages: Message[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`messages_${conversationId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'messages', filter: `conversation_id=eq.${conversationId}` },
        async () => {
          const messages = await this.getMessages(conversationId)
          callback(messages)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },
}
