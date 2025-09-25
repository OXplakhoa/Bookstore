using System;
public class Notification 
{
    public int NotificationId {get; set;}
    public string? UserId {get; set;}
    public string? Message {get; set;}
    public DateTime CreatedAt {get; set;} = DateTime.UtcNow;
}