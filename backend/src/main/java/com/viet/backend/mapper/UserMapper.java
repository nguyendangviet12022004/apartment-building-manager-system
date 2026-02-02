package com.viet.backend.mapper;

import com.viet.backend.dto.RegisterRequest;
import com.viet.backend.dto.UserDto;
import com.viet.backend.model.User;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface UserMapper {

  User toEntity(RegisterRequest request);

  UserDto toDto(User user);
}
