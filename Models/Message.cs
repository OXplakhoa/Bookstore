using System;
public class Message 
{
    public int MessageId {get; set;}
    public string? SenderId {get; set;}
    public string? ReceiverId {get; set;}
    public string? Content {get; set;}
    public DateTime CreatedAt {get; set;} = DateTime.UtcNow;
}